#!/usr/bin/env python
"""Step 11 — find idioms Wiktionary has that our dictionary doesn't, and write
them in the shape step 4 generates from.

Arth's phrase set was capped at 3,000 by 02_select long before idioms were a
feature, and only ~240 of those survive step 9's rules. Wiktionary attests
about nine thousand English idioms. This step picks the best of the ones we
are missing, so they can be given a Hindi layer like any other entry:

    python 11_more_idioms.py --n 2000
    python 04_generate.py --mode batch-submit --in data/idioms-extract.json --name idioms
    python 04_generate.py --mode batch-fetch  --name idioms --out data/idioms-generated.jsonl
    python 05_load.py --in data/idioms-generated.jsonl --extract data/idioms-extract.json
    python 09_idioms.py --extract data/extract-full.json data/idioms-extract.json
    python 10_load_idioms.py

Only phrases step 9 would go on to accept are selected, so nothing is
generated that the idioms feature would then throw away. Ranking is by
`phrase_weight` — how many languages editors bothered to translate the phrase
into — the same commonness signal 02_select and 03_extract already use, so
"thick as thieves" is picked and "Roma locuta est" is not.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any

from arth_pipeline.config import DATA_DIR, PIPELINE_DIR, config
from arth_pipeline.idioms import (
    TEACHABLE_POS,
    idiom_phrase_ok,
    idiomatic_senses,
    phrase_weight,
    teachable_phrase,
)
from arth_pipeline.normalize import normalize_word
from arth_pipeline.wiktionary import CONTENT_POS, gloss_text, iter_entries


def _load(name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name.replace(".py", ""), Path(PIPELINE_DIR) / name)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(mod)
    return mod


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--n", type=int, default=2000, help="how many new idioms to keep")
    ap.add_argument(
        "--include-unranked",
        action="store_true",
        help="keep a phrase built on a word outside the dictionary, ranked just past it",
    )
    ap.add_argument("--select", type=Path, default=DATA_DIR / "select-full.json")
    ap.add_argument("--out", type=Path, default=DATA_DIR / "idioms-extract.json")
    args = ap.parse_args()

    extract = _load("03_extract.py")

    chosen_before = json.loads(args.select.read_text(encoding="utf-8"))["headwords"]
    have = {h["word"] for h in chosen_before}
    lemma_rank = {h["word"]: h["freqRank"] for h in chosen_before if not h["isPhrase"]}
    print(f"dictionary has {len(have):,} headwords ({len(lemma_rank):,} single words)", file=sys.stderr)

    # One pass: every multi-word entry with a usable idiomatic sense that we
    # do not already carry. Entries are kept whole — a phrase can have one
    # POS entry per etymology, and extract_word merges them.
    found: dict[str, list[dict[str, Any]]] = {}
    weight: dict[str, int] = {}

    def keep(word: str, pos: str) -> bool:
        return " " in word and pos in CONTENT_POS and word not in have and teachable_phrase(word)

    for e in iter_entries(keep):
        word = e["word"]
        # idiom_phrase_ok, not select.phrase_ok: the latter guards the in-text
        # matcher, and its four-token cap and placeholder rule exclude about
        # 3,100 real idioms. `idiomatic_senses` is the stronger test of whether
        # the phrase has something to teach, and it is applied here too.
        if not idiom_phrase_ok(word) or not idiomatic_senses(e):
            continue
        found.setdefault(word, []).append(e)
        weight[word] = weight.get(word, 0) + phrase_weight(e)
    print(f"wiktionary offers {len(found):,} idioms we don't have", file=sys.stderr)

    # freqRank from the rarest constituent, exactly as 02_select does for
    # phrases: it drives which model step 4 routes the entry to.
    rows: list[dict[str, Any]] = []
    unresolved = untaught = 0
    # A phrase can contain a word the dictionary does not carry: a possessive
    # ("devil's advocate", "wolf in sheep's clothing") or a word outside the
    # top-20k slice ("eggshells", "hooky", "haystack"). Dropping the phrase for
    # it threw away the best-known idioms in the set, so with
    # --include-unranked the rank comes from the words that DO resolve.
    #
    # Taking the unresolved word as "rarer than everything" instead would park
    # the phrase at the end of the dictionary, outside the seed slice, and the
    # app's idiom list inner-joins `entries` — so it would load into Mongo and
    # never reach a phone. The rarest-constituent rank is a crude proxy for a
    # phrase either way; `weight` is what decides whether a reader meets it.
    unranked_at = max(lemma_rank.values()) + 1
    unranked_words: list[str] = []
    for word, entries in found.items():
        ranks = []
        unknown = False
        for t in word.split(" "):
            k = normalize_word(t)
            if k not in lemma_rank:
                if not args.include_unranked:
                    break
                unknown = True
                continue
            ranks.append(lemma_rank[k])
        else:
            if unknown:
                unranked_words.append(word)
                # Only when the phrase is built entirely from words we lack.
                if not ranks:
                    ranks.append(unranked_at)
            x = extract.extract_word(word, entries, True, plain_examples_only=True)
            if x is None:
                continue
            # Only what step 9 will accept: an idiomatic sense that survived
            # the sense cap and landed on a teachable part of speech.
            glosses = {gloss_text(s) for e in entries for s in idiomatic_senses(e)}
            if not any(s["gloss"] in glosses and s["partOfSpeech"] in TEACHABLE_POS for s in x["senses"]):
                untaught += 1
                continue
            r = max(ranks)
            x["freqRank"] = r
            x["tier"] = "top" if r <= config.top_tier_size else "tail"
            x["weight"] = weight[word]
            rows.append(x)
            continue
        unresolved += 1

    rows.sort(key=lambda e: (-e["weight"], e["freqRank"], e["word"]))
    kept = rows[: args.n]
    for r in kept:
        del r["weight"]

    args.out.write_text(json.dumps({"forms": {}, "entries": kept}, ensure_ascii=False, indent=1), "utf-8")
    senses = sum(len(r["senses"]) for r in kept)
    tiers = {t: sum(1 for r in kept if r["tier"] == t) for t in ("top", "tail")}
    print(
        f"wrote {args.out}: {len(kept)} idioms, {senses} senses "
        f"({tiers['top']} top / {tiers['tail']} tail); "
        f"{unresolved} skipped (a word not in the dictionary), {untaught} (no teachable idiomatic sense)"
    )
    if unranked_words:
        seen = sorted(set(unranked_words))
        kept_unranked = [r["word"] for r in kept if r["word"] in set(seen)]
        print(
            f"  {len(seen)} contain a word the dictionary lacks, ranked from the rest "
            f"({len(kept_unranked)} kept): {kept_unranked[:12]}"
        )
    print("  first 20:", [r["word"] for r in kept[:20]])


if __name__ == "__main__":
    main()
