#!/usr/bin/env python
"""Step 9 — pick the idioms out of the dictionary into data/idioms.json.

Arth's 3,000 multi-word entries are mostly functional ("how are you", "in
front of"). Wiktionary marks the real idioms with an `idiomatic` sense tag,
and those entries already carry a Hindi meaning, a definition and examples
from step 4 — so an idiom needs no new generation, only selecting.

Two things matter beyond the selection:

  senseIndex  WHICH sense is the idiomatic one. "peanut butter" is an idiom
              for spreading resources too thin, but its first sense is the
              spread — a card showing sense 0 would teach nothing. The
              idiomatic sense is matched back to our entry by its gloss, and
              an idiom whose idiomatic sense didn't survive step 3's cut is
              dropped: we have no Hindi for it.
  tags        register labels (informal, slang, humorous, dated, British…)
              in Hindi, from that sense — what a reader is told before using
              a phrase in front of their boss.
  etymology   Wiktionary's own prose, where it has one (about a quarter).
              This is "the story behind it", in English, attributed.
  weight      How many languages editors have translated the phrase into:
              evidence a reader will actually meet it. This orders the browse
              list and so decides the day's ten. freqRank cannot: it is the
              rank of the phrase's RAREST WORD, so it rates "keep good time"
              above "spill the beans" and fills the list with collocations.

Phrasal verbs ("get by", "look up") are carried too, marked `kind: phrasal`.
The word screen lists them under their headword, which only helps a reader who
already met the word; they are as much a thing to be taught as the idioms, and
the reader asked for them by name.

Usage:  python 09_idioms.py [--extract data/extract-new.json] [--out data/idioms.json]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from arth_pipeline.config import DATA_DIR
from arth_pipeline.idioms import (
    MIN_ETYMOLOGY,
    TEACHABLE_POS,
    idiomatic_senses,
    phrase_kind,
    phrase_weight,
    register_tags,
    teachable_phrase,
)
from arth_pipeline.wiktionary import CONTENT_POS, gloss_text, iter_entries


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument(
        "--extract",
        type=Path,
        nargs="+",
        default=[DATA_DIR / "extract-full.json"],
        help="the extract(s) the live `entries` came from; senseIndex indexes their ordering",
    )
    ap.add_argument("--out", type=Path, default=DATA_DIR / "idioms.json")
    args = ap.parse_args()

    entries: list[dict[str, Any]] = []
    for path in args.extract:
        entries += json.loads(path.read_text(encoding="utf-8"))["entries"]
    phrases = {
        e["word"]: e for e in entries if e["isPhrase"] and teachable_phrase(e["word"], phrasal_ok=True)
    }
    print(f"{len(phrases):,} phrase entries to consider", file=sys.stderr)

    found: dict[str, dict[str, Any]] = {}
    dropped_unmatched = 0
    for e in iter_entries(lambda w, p: w in phrases and p in CONTENT_POS):
        word = e["word"]
        # Our entry's glosses, in our order: the bridge back to a sense index.
        ours = {s["gloss"]: s for s in phrases[word]["senses"]}
        counted = False
        for s in idiomatic_senses(e):
            tags = set(s.get("tags") or ())
            mine = ours.get(gloss_text(s))
            if mine is None:
                dropped_unmatched += 1
                continue
            if mine["partOfSpeech"] not in TEACHABLE_POS:
                continue
            row = found.get(word)
            # The first idiomatic sense that survived our cut wins; later ones
            # only add their labels.
            if row is None:
                row = found[word] = {
                    "word": word,
                    "senseIndex": mine["index"],
                    "freqRank": phrases[word]["freqRank"],
                    "weight": 0,
                    "kind": phrase_kind(word),
                    "tagSet": set(),
                    "etymology": "",
                }
            row["tagSet"] |= tags
            if not counted:
                row["weight"] += phrase_weight(e)
                counted = True
            ety = (e.get("etymology_text") or "").strip()
            if len(ety) >= MIN_ETYMOLOGY and len(ety) > len(row["etymology"]):
                row["etymology"] = ety

    out = [
        {
            "word": r["word"],
            "senseIndex": r["senseIndex"],
            "freqRank": r["freqRank"],
            "weight": r["weight"],
            "kind": r["kind"],
            "tags": register_tags(r["tagSet"]),
            "etymology": r["etymology"],
        }
        for r in found.values()
    ]
    # Best-known first: the daily ten and the browse list open with idioms a
    # reader will actually meet. freqRank only breaks ties.
    out.sort(key=lambda r: (-r["weight"], r["freqRank"], r["word"]))

    args.out.write_text(json.dumps({"idioms": out}, ensure_ascii=False, indent=1), "utf-8")
    tagged = sum(1 for r in out if r["tags"])
    unweighted = sum(1 for r in out if not r["weight"])
    phrasal = sum(1 for r in out if r["kind"] == "phrasal")
    with_ety = sum(1 for r in out if r["etymology"])
    not_first = sum(1 for r in out if r["senseIndex"] != 0)
    print(
        f"wrote {args.out}: {len(out)} idioms; {tagged} with a register label, "
        f"{with_ety} with an etymology, {not_first} whose idiom is not sense 1, "
        f"{unweighted} with no translations to rank by, {phrasal} phrasal verbs "
        f"({dropped_unmatched} senses dropped: no Hindi for them)"
    )


if __name__ == "__main__":
    main()
