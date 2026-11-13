"""The sense cap, the ordering penalties and the style labels — the three
things that decide which meanings of a word a reader is ever shown."""

import importlib.util
from pathlib import Path
from typing import Any

from arth_pipeline import idioms
from arth_pipeline.config import PIPELINE_DIR, config
from arth_pipeline.wiktionary import sense_is_dropped, sense_register


def _load(name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name.replace(".py", ""), Path(PIPELINE_DIR) / name)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(mod)
    return mod


extract = _load("03_extract.py")


def sense(
    gloss: str, *, tags: list[str] | None = None, translations: int = 0, example: str | None = None
) -> dict:
    s: dict[str, Any] = {"glosses": [gloss]}
    if tags:
        s["tags"] = tags
    if translations:
        s["translations"] = [{"word": f"w{i}"} for i in range(translations)]
    if example:
        s["examples"] = [{"text": example}]
    return s


def entry(pos: str, senses: list[dict]) -> dict:
    return {"word": "get", "pos": pos, "senses": senses}


class TestStyleLabels:
    def test_wiktionarys_label_becomes_a_hindi_one(self) -> None:
        assert sense_register(sense("x", tags=["slang"])) == "स्लैंग"
        assert sense_register(sense("x", tags=["informal"])) == "अनौपचारिक"
        assert sense_register(sense("x", tags=["archaic"])) == "पुराना"
        assert sense_register(sense("x", tags=["British"])) == "ब्रिटिश"

    def test_a_plain_sense_carries_none(self) -> None:
        assert sense_register(sense("x")) == ""
        assert sense_register(sense("x", tags=["transitive"])) == ""

    def test_the_strongest_label_wins(self) -> None:
        assert sense_register(sense("x", tags=["informal", "slang"])) == "स्लैंग"


class TestWhatIsDropped:
    def test_slang_and_informal_senses_are_kept(self) -> None:
        """The complaint this whole change answers: a reader looking up a
        common word was never shown its slang sense."""
        for tag in ("slang", "informal", "humorous", "rare", "nonstandard", "dialectal"):
            assert not sense_is_dropped(sense("x", tags=[tag])), tag

    def test_dead_and_unprintable_senses_stay_out(self) -> None:
        for tag in ("obsolete", "misspelling", "vulgar", "offensive", "derogatory"):
            assert sense_is_dropped(sense("x", tags=[tag])), tag

    def test_a_sense_with_no_gloss_is_not_a_sense(self) -> None:
        assert sense_is_dropped({"tags": []})


class TestOrdering:
    def test_a_marked_sense_ranks_below_a_plain_one_of_equal_evidence(self) -> None:
        plain = extract.sense_score(sense("x", translations=10))
        slang = extract.sense_score(sense("x", tags=["slang"], translations=10))
        archaic = extract.sense_score(sense("x", tags=["archaic"], translations=10))
        assert archaic < slang < plain

    def test_only_the_heaviest_label_counts(self) -> None:
        """Archaic and rare together is not twice as obscure as archaic."""
        one = extract.sense_score(sense("x", tags=["archaic"], translations=10))
        both = extract.sense_score(sense("x", tags=["archaic", "slang"], translations=10))
        assert one == both

    def test_a_well_attested_slang_sense_still_beats_an_unused_plain_one(self) -> None:
        slang = extract.sense_score(sense("x", tags=["slang"], translations=40, example="He got me."))
        plain = extract.sense_score(sense("x", translations=1))
        assert slang > plain


class TestTheCap:
    def test_a_word_keeps_far_more_than_the_old_eight_senses(self) -> None:
        senses = [sense(f"meaning {i}", translations=50 - i, example=f"Example {i}.") for i in range(40)]
        out = extract.extract_word("get", [entry("verb", senses)], False)
        assert out is not None
        assert len(out["senses"]) == config.max_senses_per_entry
        assert config.max_senses_per_entry >= 25

    def test_senses_are_numbered_from_zero_in_the_order_shown(self) -> None:
        senses = [sense(f"meaning {i}", translations=50 - i) for i in range(10)]
        out = extract.extract_word("get", [entry("verb", senses)], False)
        assert [s["index"] for s in out["senses"]] == list(range(10))

    def test_every_sense_carries_its_style_label(self) -> None:
        out = extract.extract_word(
            "get",
            [
                entry(
                    "verb",
                    [
                        sense("to obtain", translations=50),
                        sense("to annoy", tags=["slang"], translations=30),
                    ],
                )
            ],
            False,
        )
        labels = [s["styleLabel"] for s in out["senses"]]
        assert labels == ["", "स्लैंग"]

    def test_a_noun_and_a_verb_both_keep_a_place(self) -> None:
        out = extract.extract_word(
            "get",
            [
                entry("verb", [sense(f"v{i}", translations=50) for i in range(30)]),
                entry("noun", [sense("offspring", translations=12)]),
            ],
            False,
        )
        assert "संज्ञा" in {s["partOfSpeech"] for s in out["senses"]}


class TestIdiomExamples:
    """An idiom card shows the phrase in a sentence, so the sentence matters."""

    def _sense_with(self, *examples: dict) -> dict:
        return {"glosses": ["x"], "examples": list(examples)}

    def test_a_citation_is_dropped_rather_than_used_as_a_fallback(self) -> None:
        s = self._sense_with(
            {"text": "Too many white lies and white lines", "type": "quotation", "ref": "1998"}
        )
        assert extract.sense_examples(s, 2) != []
        assert extract.sense_examples(s, 2, plain_only=True) == []

    def test_a_real_usage_example_is_kept_either_way(self) -> None:
        s = self._sense_with({"text": "She told a white lie."})
        assert extract.sense_examples(s, 2, plain_only=True) == ["She told a white lie."]

    def test_a_plain_example_still_wins_over_a_citation(self) -> None:
        s = self._sense_with(
            {"text": "A quoted line from a song", "type": "quotation", "ref": "1998"},
            {"text": "She told a white lie."},
        )
        assert extract.sense_examples(s, 2, plain_only=True) == ["She told a white lie."]

    def test_the_default_is_unchanged_for_the_dictionary(self) -> None:
        s = self._sense_with({"text": "A quoted line", "type": "quotation", "ref": "1998"})
        assert extract.sense_examples(s, 2) == ["A quoted line"]

    def test_a_citation_inside_the_example_text_is_dropped(self) -> None:
        # Wiktionary never tagged this one: the source is in the example itself.
        cited = (
            '"Only force of habit will explain why people today do honor to'
            ' Christopher Columbus." - New York Times, 1937'
        )
        s = self._sense_with({"text": cited})
        assert extract.sense_examples(s, 2, plain_only=True, word="force of habit") == []
        assert extract.sense_examples(s, 2) == [cited]  # the dictionary keeps it

    def test_a_sentence_explaining_the_phrase_is_not_an_example(self) -> None:
        s = self._sense_with(
            {"text": 'To "walk the straight and narrow" means to live a moral, disciplined life.'}
        )
        assert extract.sense_examples(s, 2, plain_only=True, word="straight and narrow") == []

    def test_a_sentence_glossing_some_other_word_is_a_real_use(self) -> None:
        # "beats me" is used here; it is "tergiversate" that is being asked about.
        used = 'Do you have any idea what "tergiversate" means? Beats me!'
        s = self._sense_with({"text": used})
        assert extract.sense_examples(s, 2, plain_only=True, word="beats me") == [used]

    def test_a_year_inside_a_sentence_is_not_an_attribution(self) -> None:
        used = "He quit smoking cold turkey in 1998."
        s = self._sense_with({"text": used})
        assert extract.sense_examples(s, 2, plain_only=True, word="cold turkey") == [used]

    def test_dialogue_is_kept_for_a_phrase_that_answers_something(self) -> None:
        used = '"Do you folks want any dessert?" "No, we are all set."'
        s = self._sense_with({"text": used})
        assert extract.sense_examples(s, 2, plain_only=True, word="all set") == [used]


class TestWhatCanBeAnIdiom:
    """02_select's phrase rule guards the in-text matcher; idioms need a weaker one."""

    def test_the_four_token_cap_does_not_apply(self) -> None:
        assert idioms.idiom_phrase_ok("let the cat out of the bag")
        assert idioms.idiom_phrase_ok("hit the nail on the head")
        assert idioms.idiom_phrase_ok("sticks and stones may break my bones")

    def test_a_placeholder_slot_is_part_of_the_idiom(self) -> None:
        assert idioms.idiom_phrase_ok("pull the wool over someone's eyes")
        assert idioms.idiom_phrase_ok("hold one's horses")
        # The slot is why 02_select rejects it: it never appears in real text.
        assert "someone's" in idioms.PLACEHOLDER_TOKENS

    def test_a_single_word_is_not_a_phrase(self) -> None:
        assert not idioms.idiom_phrase_ok("bucket")
        assert not idioms.idiom_phrase_ok("")

    def test_reduplication_is_not_an_idiom_to_teach(self) -> None:
        assert not idioms.idiom_phrase_ok("temper temper")

    def test_a_capitalised_phrase_stays_out(self) -> None:
        # Entries are keyed lowercase; step 9 keys idioms by the extract's
        # spelling, so these two would never meet.
        assert not idioms.idiom_phrase_ok("go Dutch")
        assert not idioms.idiom_phrase_ok("Jane Doe")

    def test_a_token_that_cannot_be_part_of_a_key_is_rejected(self) -> None:
        assert not idioms.idiom_phrase_ok("take 5 minutes")
        assert not idioms.idiom_phrase_ok("over- the top")
        assert not idioms.idiom_phrase_ok("'tis the season")


class TestPhrasalVerbs:
    """They share a screen with the idioms but are a different thing."""

    def test_a_verb_plus_particles_is_phrasal(self) -> None:
        assert idioms.phrase_kind("give up") == "phrasal"
        assert idioms.phrase_kind("take off") == "phrasal"
        assert idioms.phrase_kind("get away with") == "phrasal"

    def test_a_picture_is_an_idiom(self) -> None:
        assert idioms.phrase_kind("spill the beans") == "idiom"
        assert idioms.phrase_kind("night owl") == "idiom"

    def test_step_9_keeps_them_and_step_11_does_not(self) -> None:
        # Step 9 puts a card on an entry we already have; step 11 decides what
        # to pay a model to write, and a phrasal verb there is a new entry.
        assert idioms.teachable_phrase("give up", phrasal_ok=True)
        assert not idioms.teachable_phrase("give up")
        assert idioms.teachable_phrase("spill the beans")

    def test_a_phrase_of_only_function_words_is_neither(self) -> None:
        assert not idioms.teachable_phrase("of the", phrasal_ok=True)
