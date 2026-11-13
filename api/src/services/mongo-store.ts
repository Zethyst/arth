import { EntryModel, FormModel, PhraseModel, SenseNotesModel, WiktionaryModel, toDictionaryEntry } from '../db/models/index.js';
import type { DictionaryEntry, WiktionaryExtract } from '../contracts.js';
import type { LemmaStore } from './lemma.js';
import type { PhraseStore } from './phrases.js';
import type { SenseNotesStore } from './context.js';
import type { EntryTier, StagingStore } from './ondemand.js';
import type { RelatedPhraseStore } from './related-phrases.js';
import { escapeRegExp } from '../lib/regex.js';

export type Store = LemmaStore & PhraseStore & SenseNotesStore & StagingStore & RelatedPhraseStore;

export const mongoStore: Store = {
  async findEntry(id: string): Promise<DictionaryEntry | null> {
    const doc = await EntryModel.findById(id).lean();
    return doc ? toDictionaryEntry(doc) : null;
  },
  async findFormLemma(form: string): Promise<string | null> {
    const doc = await FormModel.findById(form).lean();
    return doc?.lemma ?? null;
  },
  async findPhraseLemma(phrase: string): Promise<string | null> {
    const doc = await PhraseModel.findById(phrase).lean();
    return doc?.lemma ?? null;
  },
  /**
   * Every phrase a tap could match, in one query on the `firstToken` index.
   * The alternative is one findById per window, and a nine-token window set
   * is 44 of them.
   */
  async findPhrasesByFirstToken(firstTokens: string[], maxTokens: number) {
    const docs = await PhraseModel.find(
      { firstToken: { $in: firstTokens }, tokenCount: { $lte: maxTokens } },
      { lemma: 1 },
    ).lean();
    return docs.map((d) => ({ phrase: d._id, lemma: d.lemma }));
  },
  /**
   * Phrase lemmas that use [lemma] as a whole token. The `phrases` collection
   * is a few thousand tiny documents, so the unanchored regex is a scan of a
   * collection that fits in a page or two — cheaper than the multikey index
   * the alternative would need, and it needs no migration.
   */
  async findPhrasesUsing(lemma: string, limit: number): Promise<string[]> {
    const token = new RegExp(`(^|\\s)${escapeRegExp(lemma)}(\\s|$)`);
    const docs = await PhraseModel.find({ lemma: token }, { lemma: 1 }).limit(limit * 4).lean();
    const seen = new Set<string>();
    for (const d of docs) {
      if (seen.size >= limit) break;
      seen.add(d.lemma);
    }
    return [...seen];
  },
  async findSenseNotes(word: string): Promise<string[] | null> {
    const doc = await SenseNotesModel.findById(word).lean();
    return doc?.notes ?? null;
  },
  async findStaged(lemma: string) {
    const doc = await WiktionaryModel.findById(lemma).lean();
    return doc ? { extract: doc.extract as WiktionaryExtract, freqRank: doc.freqRank } : null;
  },
  async saveGenerated(entry: DictionaryEntry, meta: { freqRank: number; model: string; tier: EntryTier }) {
    await EntryModel.updateOne(
      { _id: entry.word },
      { $set: { ...entry, freqRank: meta.freqRank, tier: meta.tier, model: meta.model, updatedAt: new Date() } },
      { upsert: true },
    );
  },
};
