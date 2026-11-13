#!/usr/bin/env python
"""Compare a fresh extract against the one the live dictionary was generated
from, and split the difference into the two piles that matter:

  regenerate  the word's SENSES changed — a sense was added, dropped or
              reordered. Only the model can write the Hindi for those, so
              these cost money.
  relabel     the senses are identical, in the same order, and only the
              style label (स्लैंग, पुराना…) is new. Labels come from
              Wiktionary, not from the model, so these are patched straight
              into the generated rows for free.

Writes data/regenerate.txt (for 04_generate --words-file) and
data/generated-relabelled.jsonl, and prices the first pile from the token
usage the original run actually recorded.

Usage:  python tool/diff_extracts.py [--old data/extract-full.json]
                                     [--new data/extract-new.json]
                                     [--generated data/generated-full.jsonl]
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from arth_pipeline.config import DATA_DIR, config, read_jsonl  # noqa: E402


def senses_of(entry: dict) -> list[tuple[str, str]]:
    """What identifies a sense for the model: its gloss and its part of speech."""
    return [(s["gloss"], s["partOfSpeech"]) for s in entry["senses"]]


def labels_of(entry: dict) -> list[str]:
    return [s.get("styleLabel", "") for s in entry["senses"]]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--old", type=Path, default=DATA_DIR / "extract-full.json")
    ap.add_argument("--new", type=Path, default=DATA_DIR / "extract-new.json")
    ap.add_argument("--generated", type=Path, default=DATA_DIR / "generated-full.jsonl")
    ap.add_argument("--out-words", type=Path, default=DATA_DIR / "regenerate.txt")
    ap.add_argument("--out-relabelled", type=Path, default=DATA_DIR / "generated-relabelled.jsonl")
    args = ap.parse_args()

    old = {e["word"]: e for e in json.loads(args.old.read_text(encoding="utf-8"))["entries"]}
    new = {e["word"]: e for e in json.loads(args.new.read_text(encoding="utf-8"))["entries"]}
    print(f"old {len(old):,} entries, new {len(new):,}")

    regenerate: list[str] = []
    relabel: list[str] = []
    unchanged = 0
    added = Counter()
    for word, n in new.items():
        o = old.get(word)
        if o is None:
            regenerate.append(word)
            continue
        if senses_of(o) != senses_of(n):
            regenerate.append(word)
            added[len(n["senses"]) - len(o["senses"])] += 1
        elif labels_of(n) != labels_of(o):
            relabel.append(word)
        else:
            unchanged += 1
    gone = sorted(set(old) - set(new))

    total_old = sum(len(e["senses"]) for e in old.values())
    total_new = sum(len(e["senses"]) for e in new.values())
    print(f"senses {total_old:,} → {total_new:,}  ({total_new - total_old:+,}, {total_new / total_old:.2f}×)")
    print(
        f"regenerate {len(regenerate):,}   relabel-only {len(relabel):,}   "
        f"unchanged {unchanged:,}   dropped {len(gone):,}"
    )
    if added:
        gains = sorted(added.items())
        print("  senses gained per regenerated word:", {k: v for k, v in gains if k})

    # Price the regeneration from what the first run actually spent per sense.
    rows = read_jsonl(args.generated) if args.generated.exists() else []
    by_word = {r["word"]: r for r in rows}
    spent_in = spent_out = counted_senses = 0
    for r in rows:
        u = r.get("usage") or {}
        spent_in += u.get("input", 0)
        spent_out += u.get("output", 0)
        counted_senses += len(r["entry"]["senses"])
    if counted_senses:
        in_per = spent_in / counted_senses
        out_per = spent_out / counted_senses
        print(f"  last run averaged {in_per:.0f} input / {out_per:.0f} output tokens per sense")
        # Each word is priced on the model its tier actually uses: the common
        # words (top) go to the better, dearer model.
        total = 0.0
        by_tier: Counter[str] = Counter()
        for word in regenerate:
            tier = new[word].get("tier", "tail")
            by_tier[tier] += len(new[word]["senses"])
        for tier, want in sorted(by_tier.items()):
            model = config.model_for_tier(tier)
            pricing = config.pricing(model)
            if pricing is None:
                print(f"  {tier}: {want:,} senses on {model} — set PRICE_INPUT_{model} to price it")
                continue
            usd = (
                want * in_per / 1e6 * pricing.input_per_m + want * out_per / 1e6 * pricing.output_per_m
            ) * config.batch_discount
            total += usd
            print(f"  {tier}: {want:,} senses on {model} ~${usd:.2f}")
        if total:
            print(f"  ~${total:.2f} in batch, all told")

    args.out_words.write_text("\n".join(regenerate) + "\n", encoding="utf-8")
    print(f"wrote {args.out_words}: {len(regenerate):,} words for 04_generate --words-file")

    # Patch the free pile: same senses, new labels.
    patched = 0
    with args.out_relabelled.open("w", encoding="utf-8") as f:
        for word in relabel:
            row = by_word.get(word)
            if row is None:
                continue
            for sense, label in zip(row["entry"]["senses"], labels_of(new[word]), strict=False):
                sense["styleLabel"] = label
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
            patched += 1
    print(f"wrote {args.out_relabelled}: {patched:,} entries relabelled without the model")
    if gone:
        print(f"no longer extractable ({len(gone)}): {gone[:20]}")


if __name__ == "__main__":
    main()
