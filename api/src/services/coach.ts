/**
 * The speaking coach: a short role-play the learner talks their way through,
 * with their own sentences put right as they go.
 *
 * The phone does the listening and the speaking — its own recogniser, its own
 * synthesizer — so all that crosses the wire is text. That is the whole reason
 * this is affordable: a ten-turn conversation costs a few text calls rather
 * than ten minutes of audio tokens, which is the difference between a feature
 * that fits a ₹500-a-year subscription and one that does not.
 *
 * Nothing is cached except a scene's opening line, which is the same every
 * time; a conversation is unique by definition.
 */
import { createHash } from 'node:crypto';
import type { CacheStore } from '../cache/cache.js';
import type { Config } from '../config.js';
import { promptText, schemaForModel, validate, type CoachTurn } from '../contracts.js';
import { ApiError, messages } from '../lib/errors.js';
import type { ChatMessage, JsonRequest, LLMProvider, Usage } from '../llm/provider.js';
import { zeroUsage } from '../llm/provider.js';
import { completeValidated } from '../llm/validated.js';

const sha = (s: string) => createHash('sha256').update(s, 'utf8').digest('hex');

/** The scenes a learner can practise. Their labels live in the app, in both languages. */
export const SCENARIOS = {
  interview: {
    /** Who the coach is playing, and what they are after. */
    role:
      'You are David, interviewing the learner for a junior job at an Indian company. ' +
      'Ask about their background, their strengths and why they want the job. Be warm but businesslike.',
    opening: 'Good morning! Thanks for coming in. Could you start by telling me a little about yourself?',
  },
  shop: {
    role:
      'You are a shopkeeper in a clothes shop. The learner wants to buy something. ' +
      'Ask what they are looking for, offer sizes and colours, talk about the price.',
    opening: 'Hello! Come in, come in. What are you looking for today?',
  },
  doctor: {
    role:
      'You are a doctor at a clinic. The learner is the patient. Ask what is wrong, how long ' +
      'it has been going on, and what they have already tried. Be kind and unhurried.',
    opening: 'Please, sit down. Tell me — what seems to be the trouble?',
  },
  introductions: {
    role:
      'You are Priya, somebody the learner has just met at a friend’s gathering. ' +
      'Make small talk: where they are from, what they do, what they like doing.',
    opening: "Hi! I don't think we've met — I'm Priya. How do you know the host?",
  },
} as const;

export type ScenarioId = keyof typeof SCENARIOS;

export function isScenario(id: string): id is ScenarioId {
  return Object.hasOwn(SCENARIOS, id);
}

/** What has been said so far. */
export type CoachHistoryTurn = { role: 'coach' | 'learner'; text: string };

export type CoachOutcome = {
  result: CoachTurn;
  cache: 'hit' | 'miss';
  usage: Usage;
  model?: string;
};

export type CoachDeps = {
  config: Pick<Config, 'LLM_COACH_MODEL' | 'LLM_TEMPERATURE' | 'LLM_COACH_MAX_TOKENS'>;
  llm: LLMProvider;
  cache: CacheStore;
  log: { warn: (obj: object, msg: string) => void };
  spend?: () => void;
};

/**
 * The coach's next turn.
 *
 * With no history and nothing said, this is the scene's opening line, which
 * costs nothing: it is fixed per scene, so it never reaches the model.
 */
export async function coachReply(
  deps: CoachDeps,
  scenario: ScenarioId,
  history: CoachHistoryTurn[],
  said: string,
): Promise<CoachOutcome> {
  const scene = SCENARIOS[scenario];
  const utterance = said.trim();

  if (history.length === 0 && utterance === '') {
    const key = sha(`coach-open:${scenario}`);
    const cached = await deps.cache.get<CoachTurn>(key);
    if (cached) return { result: cached, cache: 'hit', usage: zeroUsage };
    // The Hindi of a fixed line is worth one call, once, for ever.
    const opening = await openingTurn(deps, scene.opening);
    await deps.cache.set(key, 'coach', opening.result);
    return opening;
  }

  if (utterance === '') throw new ApiError('BAD_REQUEST', messages.badRequest);

  deps.spend?.();
  const messagesForModel: ChatMessage[] = [
    { role: 'system', content: `${promptText('coach-system')}\n\nTHE SCENE\n${scene.role}` },
  ];
  // The history is replayed as a real conversation rather than summarised into
  // the prompt: the model keeps its own part straight that way, and a learner
  // noticing the coach forget what they just said is the end of the illusion.
  for (const turn of history) {
    messagesForModel.push(
      turn.role === 'coach'
        ? { role: 'assistant', content: JSON.stringify({ reply: turn.text }) }
        : { role: 'user', content: JSON.stringify({ said: turn.text }) },
    );
  }
  messagesForModel.push({ role: 'user', content: JSON.stringify({ said: utterance }) });

  const req: JsonRequest = {
    model: deps.config.LLM_COACH_MODEL,
    messages: messagesForModel,
    schemaName: 'coach_turn',
    schema: schemaForModel('coachTurn'),
    maxOutputTokens: deps.config.LLM_COACH_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };
  const { parsed, usage, model } = await completeValidated<CoachTurn>(deps, req, validate.coachTurn, 'coach');

  // A correction that says back exactly what they said is noise.
  const better =
    parsed.better && parsed.better.text.trim().toLowerCase() === utterance.toLowerCase()
      ? undefined
      : parsed.better;
  return { result: { ...parsed, ...(better ? { better } : { better: undefined }) }, cache: 'miss', usage, model };
}

/** The scene's fixed opening, with its Hindi. */
async function openingTurn(deps: CoachDeps, opening: string): Promise<CoachOutcome> {
  deps.spend?.();
  const req: JsonRequest = {
    model: deps.config.LLM_COACH_MODEL,
    messages: [
      { role: 'system', content: promptText('coach-system') },
      {
        role: 'user',
        content: JSON.stringify({
          task: 'Return this exact opening line as `reply`, with its Hindi as `replyHindi`. No correction.',
          reply: opening,
        }),
      },
    ],
    schemaName: 'coach_turn',
    schema: schemaForModel('coachTurn'),
    maxOutputTokens: deps.config.LLM_COACH_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };
  const { parsed, usage, model } = await completeValidated<CoachTurn>(deps, req, validate.coachTurn, 'coach');
  // The opening is ours, not the model's, however it chose to paraphrase it.
  return { result: { ...parsed, reply: opening, better: undefined }, cache: 'miss', usage, model };
}
