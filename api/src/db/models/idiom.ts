import { Schema, model, type InferSchemaType } from 'mongoose';
import type { Idiom } from '../../contracts.js';

/**
 * The idioms the app teaches. Each one points at an entry in `entries` that
 * already carries its Hindi meaning, definition and examples — this row only
 * says which of that entry's senses is the idiomatic one, how the phrase is
 * marked, where it came from and how well known it is. `_id` is the phrase,
 * so it joins to `entries._id` directly.
 */
const idiomSchema = new Schema(
  {
    _id: { type: String, required: true },
    senseIndex: { type: Number, required: true, min: 0 },
    tags: { type: [String], default: [] },
    etymology: { type: String, default: '' },
    /**
     * The entry's rank: the rank of the phrase's RAREST word. Only a
     * tie-breaker — on its own it rates "keep good time" above "spill the
     * beans", because the collocation is built from commoner words.
     */
    freqRank: { type: Number, required: true },
    /**
     * How many languages Wiktionary's editors have translated the phrase
     * into: the evidence a reader will actually meet it. This is what orders
     * the browse list and so decides the idioms a reader is shown each day.
     */
    weight: { type: Number, required: true, default: 0 },
    /**
     * `phrasal` for a verb plus particles (give up, take off), `idiom`
     * otherwise. Both are taught the same way and share a screen.
     */
    kind: { type: String, enum: ['idiom', 'phrasal'], required: true, default: 'idiom' },
    updatedAt: { type: Date, default: () => new Date() },
  },
  { versionKey: false, collection: 'idioms' },
);
idiomSchema.index({ weight: -1, freqRank: 1 });

export type IdiomDoc = InferSchemaType<typeof idiomSchema>;
export const IdiomModel = model('Idiom', idiomSchema);

export function toIdiom(doc: IdiomDoc): Idiom {
  return {
    word: doc._id,
    senseIndex: doc.senseIndex,
    tags: doc.tags,
    etymology: doc.etymology,
    freqRank: doc.freqRank,
    weight: doc.weight,
    kind: doc.kind === 'phrasal' ? 'phrasal' : 'idiom',
  };
}
