import { test, describe, after } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { validate, formatErrors } from '../src/contracts.js';
import { appOptions, FakeLLM } from './fakes.js';

const draft = {
  english: 'I have to submit this report by tomorrow.',
  vocab: [
    { en: 'have to', hi: 'करना है' },
    { en: 'submit', hi: 'जमा' },
  ],
  alternatives: [
    { tone: 'formal', text: 'This report must be submitted by tomorrow.' },
    { tone: 'casual', text: "I've got to hand this report in by tomorrow." },
  ],
};

describe('POST /v1/english', () => {
  const hindi = 'मुझे कल तक यह रिपोर्ट जमा करनी है';

  test('turns Hindi into English, with the words worth keeping', async () => {
    const llm = new FakeLLM({ english_draft: [JSON.stringify(draft)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/english', payload: { text: hindi } });
    assert.equal(r.statusCode, 200);
    const out = r.json().data;
    assert.ok(validate.englishDraft(out), formatErrors(validate.englishDraft.errors));
    assert.equal(out.english, draft.english);
    assert.equal(out.vocab[0]!.en, 'have to');
    assert.equal(out.alternatives[0]!.tone, 'formal');
  });

  test('the same Hindi is only paid for once', async () => {
    const llm = new FakeLLM({ english_draft: [JSON.stringify(draft)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const once = { method: 'POST' as const, url: '/v1/english', payload: { text: hindi } };
    await app.inject(once);
    await app.inject(once);
    assert.equal(llm.requests.length, 1);
  });

  test('empty input is a 400 before any model call', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/english', payload: { text: '   ' } });
    assert.equal(r.statusCode, 400);
    assert.equal(llm.requests.length, 0);
  });
});

describe('POST /v1/proofread', () => {
  const typed = 'I recieved your mesage yesterday and wil reply soon.';
  const fixed = {
    corrected: 'I received your message yesterday and will reply soon.',
    fixes: [
      { wrong: 'recieved', right: 'received', kind: 'spelling', why: 'सही वर्तनी "received" है।' },
      { wrong: 'mesage', right: 'message', kind: 'spelling', why: '"message" में दो s आते हैं।' },
      { wrong: 'wil', right: 'will', kind: 'spelling', why: '"will" में दो l आते हैं।' },
    ],
  };

  test('corrects the text and names each fix so it can be underlined', async () => {
    const llm = new FakeLLM({ proofread: [JSON.stringify({ ...fixed, alternatives: [] })] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/proofread', payload: { text: typed } });
    assert.equal(r.statusCode, 200);
    const out = r.json().data;
    assert.ok(validate.proofread(out), formatErrors(validate.proofread.errors));
    assert.equal(out.fixes.length, 3);
    // Every fix has to be findable in what the writer typed.
    for (const f of out.fixes) assert.ok(typed.includes(f.wrong), `${f.wrong} is in the text`);
  });

  test('a fix the model paraphrased instead of quoting is dropped', async () => {
    // The editor underlines by searching for `wrong`; one that is not there
    // would underline nothing, so it is no use to the reader.
    const llm = new FakeLLM({
      proofread: [
        JSON.stringify({
          corrected: 'I received your message.',
          fixes: [
            { wrong: 'recieved', right: 'received', kind: 'spelling', why: 'वर्तनी।' },
            { wrong: 'the whole sentence', right: 'something', kind: 'wording', why: 'ऐसा नहीं लिखा था।' },
          ],
          alternatives: [],
        }),
      ],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/proofread', payload: { text: typed } });
    assert.deepEqual(
      r.json().data.fixes.map((f: { wrong: string }) => f.wrong),
      ['recieved'],
    );
  });

  test('clean text comes back unchanged, with nothing invented', async () => {
    const clean = 'I received your message yesterday and will reply soon.';
    const llm = new FakeLLM({
      proofread: [JSON.stringify({ corrected: clean, fixes: [], alternatives: [] })],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'POST', url: '/v1/proofread', payload: { text: clean } });
    assert.equal(r.json().data.corrected, clean);
    assert.deepEqual(r.json().data.fixes, []);
  });
});
