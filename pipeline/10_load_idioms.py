#!/usr/bin/env python
"""Step 10 — load data/idioms.json into Mongo's `idioms` collection.

An idiom row is a pointer, not content: which entry, which of its senses is
the idiomatic one, how the phrase is marked, where it came from, and how
well known it is. The Hindi
is already in `entries`, so this loads in seconds and costs nothing.

Rows whose entry is not in `entries` are skipped rather than loaded: a
pointer to a word the app doesn't have would show an empty card. Idioms that
disappear from a later selection are removed, so the collection always
matches the file.

Usage:  python 10_load_idioms.py [--in data/idioms.json] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path

from pymongo import MongoClient, UpdateOne

from arth_pipeline.config import DATA_DIR, config


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--in", dest="inp", type=Path, default=DATA_DIR / "idioms.json")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    rows = json.loads(args.inp.read_text(encoding="utf-8"))["idioms"]
    now = datetime.now(UTC)

    client = MongoClient(config.mongodb_uri, serverSelectionTimeoutMS=5000)
    db = client.get_default_database()

    # Only idioms whose entry is really there, and whose idiomatic sense
    # really exists in it.
    wanted = {r["word"]: r for r in rows}
    ok: list[UpdateOne] = []
    missing = 0
    for doc in db["entries"].find({"_id": {"$in": list(wanted)}}, {"senses": 1}):
        r = wanted[doc["_id"]]
        if r["senseIndex"] >= len(doc.get("senses") or ()):
            missing += 1
            continue
        ok.append(
            UpdateOne(
                {"_id": r["word"]},
                {
                    "$set": {
                        "senseIndex": r["senseIndex"],
                        "tags": r["tags"],
                        "etymology": r["etymology"],
                        "freqRank": r["freqRank"],
                        "weight": r["weight"],
                        "kind": r["kind"],
                        "updatedAt": now,
                    }
                },
                upsert=True,
            )
        )
    absent = len(wanted) - len(ok) - missing
    print(
        f"{len(rows)} idioms in file; {len(ok)} loadable, "
        f"{absent} have no entry, {missing} point past its senses"
    )

    if args.dry_run:
        print("  (dry run)")
        return
    if ok:
        r = db["idioms"].bulk_write(ok, ordered=False)
        print(f"  idioms: {len(ok)} ops → {r.upserted_count} inserted, {r.modified_count} updated")
    gone = db["idioms"].delete_many({"_id": {"$nin": [o._filter["_id"] for o in ok]}})
    if gone.deleted_count:
        print(f"  removed {gone.deleted_count} no longer selected")
    # The browse list and the daily set order by weight, descending.
    db["idioms"].create_index([("weight", -1), ("freqRank", 1)])
    print("  indexes ensured")


if __name__ == "__main__":
    main()
