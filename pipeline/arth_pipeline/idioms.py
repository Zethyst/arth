"""What counts as an idiom worth teaching, shared by step 9 (select the ones
already in the dictionary) and step 11 (find more in Wiktionary).

Wiktionary's `idiomatic` sense tag is the starting point, but it is broader
than a learner's idea of an idiom: it covers grammatical phrases ("at all"),
set phrases whose parts are ordinary ("carbonated water"), and phrasal verbs.
These rules narrow it to phrases a reader would actually set out to learn.
"""

from __future__ import annotations

from typing import Any

from arth_pipeline.wiktionary import REGISTER_LABELS

# A sense carrying one of these has no business on a learning card: either the
# app never shows it at all, or it stands in for something a reader did not ask
# to be taught. "special military operation" is tagged euphemistic and
# neologism, and is a state's name for an invasion — not an idiom.
UNUSABLE: frozenset[str] = frozenset(
    {
        "vulgar",
        "offensive",
        "derogatory",
        "obsolete",
        "euphemistic",
        "neologism",
        "ethnic-slur",
        "religious-slur",
    }
)

# Parts of speech that name a thing, an action or a quality. An idiomatic
# adverb or conjunction ("at first", "so long as") is grammar, not an idiom.
TEACHABLE_POS: frozenset[str] = frozenset({"संज्ञा", "क्रिया", "मुहावरा", "विशेषण", "विस्मयादिबोधक"})

# A phrase made only of these says nothing on its own ("at all", "about to").
FUNCTION_WORDS: frozenset[str] = frozenset(
    """
a an the and or but if so as at by for from in into of off on out to up with
be is am are was were been being do does did have has had will would shall
should can could may might must not no nor than then that this these those
there here it its he she they them his her their you your we our i me my
all any some such very too just only own same other another each every both
few more most much many say said like what which who whom whose when where
why how about after again against because before below between down during
further once over under until while
""".split()
)

# Verb + particle: already listed on the headword's own page, so an idioms
# feature that repeated them would be showing the same thing twice.
PARTICLES: frozenset[str] = frozenset(
    """
about across after ahead along apart around aside at away back behind by down
for forward in into of off on onto out over past round through to together
towards under up upon with
""".split()
)

# An etymology shorter than this is a stub ("Unknown.") and says nothing.
MIN_ETYMOLOGY = 60


def is_phrasal_verb(phrase: str) -> bool:
    tokens = phrase.split()
    return len(tokens) >= 2 and all(t in PARTICLES for t in tokens[1:])


def says_something(phrase: str) -> bool:
    """At least one word that carries meaning of its own."""
    return any(t not in FUNCTION_WORDS for t in phrase.split())


def phrase_kind(phrase: str) -> str:
    """`phrasal` for a verb plus particles (give up, take off); `idiom` otherwise.

    They are taught the same way and share a screen, but they are different
    things and a reader filters between them: "pick up" is a verb whose meaning
    you have to be told, "spill the beans" is a picture.
    """
    return "phrasal" if is_phrasal_verb(phrase) else "idiom"


def teachable_phrase(phrase: str, *, phrasal_ok: bool = False) -> bool:
    """The rules that need only the phrase itself, not its senses.

    Step 9 passes [phrasal_ok], because the phrasal verbs already in the
    dictionary are worth teaching alongside the idioms. Step 11 does not: it
    chooses what to *generate*, and a phrasal verb there would be a new entry
    rather than a new card on one we have.
    """
    if not says_something(phrase):
        return False
    return phrasal_ok or not is_phrasal_verb(phrase)


def idiomatic_senses(entry: dict[str, Any]) -> list[dict[str, Any]]:
    """The entry's senses that are idiomatic and showable, in Wiktionary's order."""
    out = []
    for s in entry.get("senses") or ():
        tags = set(s.get("tags") or ())
        if "idiomatic" in tags and not (tags & UNUSABLE):
            out.append(s)
    return out


def register_tags(tags: set[str]) -> list[str]:
    """Wiktionary's labels for a sense, in Hindi, in a stable order."""
    out: list[str] = []
    for tag, label in REGISTER_LABELS:
        if tag in tags and label not in out:
            out.append(label)
    return out


def phrase_weight(entry: dict[str, Any]) -> int:
    """Evidence the phrase is common: how many languages its senses are translated into.

    The same signal 03_extract uses to rank senses. "as well as" scores in the
    dozens; "for to" scores 0. This is the only commonness signal that works on a
    phrase: a phrase has no frequency rank of its own, and the rank of its rarest
    word rates "keep good time" above "spill the beans".
    """
    return sum(len(s.get("translations") or ()) for s in entry.get("senses") or ())


# Tokens that stand for whatever the sentence puts there. 02_select rejects a
# phrase containing one, because the dictionary matches phrases literally in
# running text and "someone's" never appears. An idiom card is browsed, not
# matched, and the slot is part of the idiom.
PLACEHOLDER_TOKENS: frozenset[str] = frozenset(
    {"one's", "one", "oneself", "someone", "someone's", "somebody", "something", "somewhere"}
)


def idiom_token_ok(token: str) -> bool:
    """A token that can be part of a phrase key: letters, with inner ' or -."""
    if not token or token[0] in "'-" or token[-1] == "-":
        return False
    core = token.replace("'", "").replace("-", "")
    return core.isalpha() and core.islower()


def idiom_phrase_ok(word: str) -> bool:
    """Whether [word] can be an idiom entry.

    Deliberately weaker than `02_select.phrase_ok`, which guards the in-text
    phrase matcher and so caps a phrase at four tokens and rejects placeholder
    tokens. Applying it to idioms threw away the best-known idioms in English:
    "let the cat out of the bag" and "hit the nail on the head" for length,
    "pull the wool over someone's eyes" and "hold one's horses" for their slot.

    Nothing downstream minds. `phrase_windows` only ever builds windows of two
    to four tokens, so a longer or placeholder phrase is never looked up in
    running text — it sits inert in `phrases` and still appears on its words'
    screens, which is where a reader meets it.

    Capitalised phrases ("go Dutch") stay out: entries are keyed lowercase by
    05_load, step 9 keys idioms by the extract's own spelling, and the two
    would not meet.
    """
    toks = word.split(" ")
    if len(toks) < 2 or not all(idiom_token_ok(t) for t in toks):
        return False
    # "temper temper" is a reduplication, not a phrase with a meaning to teach.
    return len(set(toks)) > 1
