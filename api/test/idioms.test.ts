import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { validate, formatErrors } from "../src/contracts.js";
import { toIdiom, type IdiomDoc } from "../src/db/models/idiom.js";

const doc = (over: Partial<IdiomDoc> = {}): IdiomDoc =>
  ({
    _id: "spill the beans",
    senseIndex: 2,
    tags: ["अनौपचारिक"],
    etymology: "From the practice of voting with beans.",
    freqRank: 3140,
    weight: 68,
    kind: 'idiom',
    updatedAt: new Date(),
    ...over,
  }) as IdiomDoc;

describe("the idiom the phone receives", () => {
  // The schema is the only definition of this shape; the mongoose model and
  // the TypeScript type are both views of it. freqRank was missing from the
  // schema for a while because nothing checked them against each other.
  test("what toIdiom returns satisfies the contract", () => {
    const wire = toIdiom(doc());
    assert.ok(validate.idiom(wire), formatErrors(validate.idiom.errors));
  });

  test("every field the app orders or labels by is carried", () => {
    const wire = toIdiom(doc());
    assert.equal(wire.word, "spill the beans");
    assert.equal(wire.senseIndex, 2);
    assert.equal(wire.weight, 68);
    assert.equal(wire.freqRank, 3140);
    assert.deepEqual(wire.tags, ["अनौपचारिक"]);
  });

  test("a phrase nobody has translated is still valid, at weight 0", () => {
    const wire = toIdiom(doc({ weight: 0, tags: [], etymology: "" }));
    assert.ok(validate.idiom(wire), formatErrors(validate.idiom.errors));
    assert.equal(wire.weight, 0);
  });

  test("a phrasal verb rides on the same row, marked as one", () => {
    const wire = toIdiom(doc({ _id: "give up", kind: "phrasal" }));
    assert.ok(validate.idiom(wire), formatErrors(validate.idiom.errors));
    assert.equal(wire.kind, "phrasal");
  });

  test("the contract rejects a row with no weight to order by", () => {
    const { weight: _w, ...without } = toIdiom(doc());
    assert.equal(validate.idiom(without), false);
  });
});
