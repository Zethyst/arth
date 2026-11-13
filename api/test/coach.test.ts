import { test, describe, after } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { validate, formatErrors } from '../src/contracts.js';
import { SCENARIOS } from '../src/services/coach.js';
import { appOptions, FakeLLM } from './fakes.js';

const turn = {
  reply: 'Three years — that is good experience. What did you work on?',
  replyHindi: 'तीन साल — यह अच्छा अनुभव है। आपने किस पर काम किया?',
  better: {
    text: 'I have been working in digital marketing for three years.',
    why: 'जो काम अब भी चल रहा है, उसके लिए present perfect continuous आता है।',
  },
};

describe('GET /v1/coach/scenarios', () => {
  test('lists the scenes, without a model or an account', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'GET', url: '/v1/coach/scenarios' });
    assert.equal(r.statusCode, 200);
    assert.deepEqual(r.json().data.scenarios.sort(), Object.keys(SCENARIOS).sort());
    assert.equal(llm.requests.length, 0);
  });
});

describe('POST /v1/coach', () => {
  const history = [
    { role: 'coach' as const, text: 'Tell me about yourself.' },
    { role: 'learner' as const, text: 'I am working in digital marketing since three years.' },
  ];

  test('answers in character and offers a better way to say it', async () => {
    const llm = new FakeLLM({ coach_turn: [JSON.stringify(turn)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: { scenario: 'interview', turns: history, said: 'I am working here since three years.' },
    });
    assert.equal(r.statusCode, 200);
    const out = r.json().data;
    assert.ok(validate.coachTurn(out), formatErrors(validate.coachTurn.errors));
    assert.equal(out.better!.text, turn.better.text);
  });

  test('the conversation so far is replayed as a conversation', async () => {
    // Summarised into the prompt, the coach forgets its own part; a learner
    // noticing that is the end of the illusion.
    const llm = new FakeLLM({ coach_turn: [JSON.stringify(turn)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: { scenario: 'interview', turns: history, said: 'Mostly social media.' },
    });
    const sent = llm.requests[0]!.messages;
    assert.equal(sent.filter((m) => m.role === 'assistant').length, 1, 'the coach had a turn');
    assert.equal(sent.filter((m) => m.role === 'user').length, 2, 'the learner had two');
    assert.ok(sent[0]!.content.includes('Vikram'), 'the scene is in the system prompt');
  });

  test('a correction that only repeats the sentence is dropped', async () => {
    const said = 'I work in marketing.';
    const llm = new FakeLLM({
      coach_turn: [
        JSON.stringify({ reply: 'Good.', replyHindi: 'अच्छा।', better: { text: said, why: 'ठीक है।' } }),
      ],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: { scenario: 'interview', turns: history, said },
    });
    assert.equal(r.json().data.better, undefined);
  });

  test('a null correction is no correction, and is not worth a retry', async () => {
    // Strict mode makes every optional property required-but-nullable, so a
    // turn that needs no correction comes back as better: null. Taking that
    // for invalid output cost a second model call on the commonest turn there
    // is — and the retry returned the same null.
    const llm = new FakeLLM({
      coach_turn: [
        JSON.stringify({ reply: 'Accha, go on.', replyHindi: 'अक्का, कहिए।', better: null, closing: null }),
      ],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: { scenario: 'interview', turns: history, said: 'I work in marketing.' },
    });
    assert.equal(r.statusCode, 200);
    assert.equal(r.json().data.better, undefined);
    assert.equal(llm.requests.length, 1, 'one call, not two');
  });

  test('the opening line is the scene’s own, whatever the model paraphrases', async () => {
    const llm = new FakeLLM({
      coach_turn: [JSON.stringify({ reply: 'Something else entirely.', replyHindi: 'कुछ और।' })],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: { scenario: 'interview', turns: [], said: '' },
    });
    assert.equal(r.json().data.reply, SCENARIOS.interview.opening);
  });

  test('an opening is paid for once, then cached for ever', async () => {
    const llm = new FakeLLM({
      coach_turn: [JSON.stringify({ reply: 'x', replyHindi: 'एक्स' })],
    });
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const open = { method: 'POST' as const, url: '/v1/coach', payload: { scenario: 'shop', turns: [], said: '' } };
    await app.inject(open);
    await app.inject(open);
    assert.equal(llm.requests.length, 1);
  });

  test('an unknown scene is a 400 before any model call', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: { scenario: 'moon-landing', turns: [], said: 'hello' },
    });
    assert.equal(r.statusCode, 400);
    assert.equal(llm.requests.length, 0);
  });

  test('a conversation longer than the cap is refused rather than billed', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({
      method: 'POST',
      url: '/v1/coach',
      payload: {
        scenario: 'shop',
        turns: Array.from({ length: 41 }, () => ({ role: 'learner', text: 'hello' })),
        said: 'hello',
      },
    });
    assert.equal(r.statusCode, 400);
    assert.equal(llm.requests.length, 0);
  });
});
