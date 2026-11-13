import { test, describe, after } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { validate, formatErrors, schemaForModel } from '../src/contracts.js';
import { appOptions, FakeLLM } from './fakes.js';

const grammar = {
  source: 'She had been waiting for an hour.',
  shape: 'कर्ता + had been + क्रिया-ing — बीते समय में चलता रहा काम।',
  points: [
    { part: 'had been waiting', label: 'काल', note: 'यह past perfect continuous है; काम पहले से चल रहा था।' },
    { part: 'for an hour', label: 'अवधि', note: '"for" बताता है कि कितनी देर से।' },
  ],
};

const summary = {
  summary: 'एलिज़ाबेथ डार्सी से मिलती है और उसका बर्ताव उसे घमंडी लगता है।',
  points: ['नाच का आयोजन होता है।', 'डार्सी किसी से नहीं नाचता।', 'एलिज़ाबेथ उसकी बात सुन लेती है।'],
  people: [{ name: 'डार्सी', who: 'अमीर और चुप रहने वाला सज्जन' }],
};

describe('POST /v1/grammar', () => {
  test('explains how the sentence is built, and caches the answer', async () => {
    const llm = new FakeLLM({ grammar_note: [JSON.stringify(grammar)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const body = { text: 'She had been waiting for an hour.' };
    const r1 = await app.inject({ method: 'POST', url: '/v1/grammar', payload: body });
    assert.equal(r1.statusCode, 200);
    const note = r1.json().data;
    assert.ok(validate.grammarNote(note), formatErrors(validate.grammarNote.errors));
    assert.equal(note.points[0]!.part, 'had been waiting');

    // Only one scripted answer: a second call must come from the cache.
    const r2 = await app.inject({ method: 'POST', url: '/v1/grammar', payload: body });
    assert.equal(r2.statusCode, 200);
    assert.deepEqual(r2.json().data, note);
    assert.equal(llm.requests.length, 1);
  });

  test('the sentence we were sent is the one reported back', async () => {
    // The model is asked to echo it; we do not take its word for that.
    const llm = new FakeLLM({ grammar_note: [JSON.stringify({ ...grammar, source: 'something else' })] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/grammar',
      payload: { text: 'She had been waiting for an hour.' },
    });
    assert.equal(r.json().data.source, 'She had been waiting for an hour.');
  });

  test('an invalid answer is retried once, then accepted', async () => {
    const llm = new FakeLLM({
      grammar_note: [JSON.stringify({ shape: 'no points' }), JSON.stringify(grammar)],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/grammar', payload: { text: 'She waited.' } });
    assert.equal(r.statusCode, 200);
    assert.equal(llm.requests.length, 2);
  });

  test('empty text is a 400 before any model call', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/grammar', payload: { text: '  ' } });
    assert.equal(r.statusCode, 400);
    assert.equal(llm.requests.length, 0);
  });
});

describe('POST /v1/summary', () => {
  const passage = 'It is a truth universally acknowledged. '.repeat(10);

  test('says what happened, in Hindi', async () => {
    const llm = new FakeLLM({ passage_summary: [JSON.stringify(summary)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/summary', payload: { text: passage } });
    assert.equal(r.statusCode, 200);
    const out = r.json().data;
    assert.ok(validate.passageSummary(out), formatErrors(validate.passageSummary.errors));
    assert.equal(out.points.length, 3);
    assert.equal(out.people![0]!.name, 'डार्सी');
  });

  test('a sentence is too short to summarise', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/summary', payload: { text: 'He left.' } });
    assert.equal(r.statusCode, 400);
    assert.equal(llm.requests.length, 0);
  });

  test('a whole book is refused, so one tap cannot cost a fortune', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/summary',
      payload: { text: 'word '.repeat(10000) },
    });
    assert.equal(r.statusCode, 400);
    assert.equal(llm.requests.length, 0);
  });

  test('the same passage is only paid for once', async () => {
    const llm = new FakeLLM({ passage_summary: [JSON.stringify(summary)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const once = { method: 'POST' as const, url: '/v1/summary', payload: { text: passage } };
    await app.inject(once);
    const r2 = await app.inject(once);
    assert.equal(r2.statusCode, 200);
    assert.equal(llm.requests.length, 1);
  });
});

describe('the schema the model is actually given', () => {
  // Strict mode refuses a schema with an optional property. A fake provider
  // never notices; the real API returns 400 on the first live call, which is
  // how /summary and /coach both shipped broken until this was found.
  test('every property is required, whatever the contract says', () => {
    for (const name of ['passageSummary', 'coachTurn', 'grammarNote', 'proofread'] as const) {
      const s = schemaForModel(name) as {
        required?: string[];
        properties?: Record<string, unknown>;
      };
      assert.deepEqual(
        [...(s.required ?? [])].sort(),
        Object.keys(s.properties ?? {}).sort(),
        `${name}: required lists every property`,
      );
    }
  });

  test('a property the contract leaves optional is made nullable instead', () => {
    const s = schemaForModel('coachTurn') as {
      properties: Record<string, { type: unknown }>;
    };
    assert.deepEqual(s.properties['better']!.type, ['object', 'null']);
    assert.deepEqual(s.properties['closing']!.type, ['boolean', 'null']);
    // One the contract requires is left alone.
    assert.equal(s.properties['reply']!.type, 'string');
  });

  test('our own validation still treats them as optional', () => {
    // The contract is the truth; the strict schema is a concession to one API.
    assert.ok(validate.coachTurn({ reply: 'Hello.', replyHindi: 'नमस्ते।' }));
  });
});
