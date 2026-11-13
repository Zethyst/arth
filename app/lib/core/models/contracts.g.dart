// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DictionaryEntry _$DictionaryEntryFromJson(Map<String, dynamic> json) =>
    _DictionaryEntry(
      word: json['word'] as String,
      ipa: json['ipa'] as String,
      hindiPronunciation: json['hindiPronunciation'] as String,
      senses: (json['senses'] as List<dynamic>)
          .map((e) => Sense.fromJson(e as Map<String, dynamic>))
          .toList(),
      synonyms: (json['synonyms'] as List<dynamic>)
          .map((e) => BilingualPair.fromJson(e as Map<String, dynamic>))
          .toList(),
      antonyms: (json['antonyms'] as List<dynamic>)
          .map((e) => BilingualPair.fromJson(e as Map<String, dynamic>))
          .toList(),
      forms: (json['forms'] as List<dynamic>)
          .map((e) => WordForm.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPhrase: json['isPhrase'] as bool,
    );

Map<String, dynamic> _$DictionaryEntryToJson(_DictionaryEntry instance) =>
    <String, dynamic>{
      'word': instance.word,
      'ipa': instance.ipa,
      'hindiPronunciation': instance.hindiPronunciation,
      'senses': instance.senses,
      'synonyms': instance.synonyms,
      'antonyms': instance.antonyms,
      'forms': instance.forms,
      'isPhrase': instance.isPhrase,
    };

_Sense _$SenseFromJson(Map<String, dynamic> json) => _Sense(
  index: (json['index'] as num).toInt(),
  partOfSpeech: json['partOfSpeech'] as String,
  meaning: json['meaning'] as String,
  definition: json['definition'] as String,
  styleLabel: json['styleLabel'] as String?,
  examples: (json['examples'] as List<dynamic>)
      .map((e) => BilingualPair.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SenseToJson(_Sense instance) => <String, dynamic>{
  'index': instance.index,
  'partOfSpeech': instance.partOfSpeech,
  'meaning': instance.meaning,
  'definition': instance.definition,
  'styleLabel': instance.styleLabel,
  'examples': instance.examples,
};

_BilingualPair _$BilingualPairFromJson(Map<String, dynamic> json) =>
    _BilingualPair(en: json['en'] as String, hi: json['hi'] as String);

Map<String, dynamic> _$BilingualPairToJson(_BilingualPair instance) =>
    <String, dynamic>{'en': instance.en, 'hi': instance.hi};

_WordForm _$WordFormFromJson(Map<String, dynamic> json) => _WordForm(
  en: json['en'] as String,
  label: json['label'] as String,
  hi: json['hi'] as String,
);

Map<String, dynamic> _$WordFormToJson(_WordForm instance) => <String, dynamic>{
  'en': instance.en,
  'label': instance.label,
  'hi': instance.hi,
};

_ContextResult _$ContextResultFromJson(Map<String, dynamic> json) =>
    _ContextResult(
      senseIndex: (json['senseIndex'] as num).toInt(),
      meaning: json['meaning'] as String,
      note: json['note'] as String,
    );

Map<String, dynamic> _$ContextResultToJson(_ContextResult instance) =>
    <String, dynamic>{
      'senseIndex': instance.senseIndex,
      'meaning': instance.meaning,
      'note': instance.note,
    };

_TranslationResult _$TranslationResultFromJson(Map<String, dynamic> json) =>
    _TranslationResult(
      source: json['source'] as String,
      hindi: json['hindi'] as String,
      simpleMeaning: json['simpleMeaning'] as String,
      difficultWords: (json['difficultWords'] as List<dynamic>)
          .map(
            (e) => TranslationResultDifficultWords.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );

Map<String, dynamic> _$TranslationResultToJson(_TranslationResult instance) =>
    <String, dynamic>{
      'source': instance.source,
      'hindi': instance.hindi,
      'simpleMeaning': instance.simpleMeaning,
      'difficultWords': instance.difficultWords,
    };

_TranslationResultDifficultWords _$TranslationResultDifficultWordsFromJson(
  Map<String, dynamic> json,
) => _TranslationResultDifficultWords(
  en: json['en'] as String,
  hi: json['hi'] as String,
);

Map<String, dynamic> _$TranslationResultDifficultWordsToJson(
  _TranslationResultDifficultWords instance,
) => <String, dynamic>{'en': instance.en, 'hi': instance.hi};

_PhraseMatch _$PhraseMatchFromJson(Map<String, dynamic> json) => _PhraseMatch(
  phrase: json['phrase'] as String,
  lemma: json['lemma'] as String,
  start: (json['start'] as num).toInt(),
  tokenCount: (json['tokenCount'] as num).toInt(),
);

Map<String, dynamic> _$PhraseMatchToJson(_PhraseMatch instance) =>
    <String, dynamic>{
      'phrase': instance.phrase,
      'lemma': instance.lemma,
      'start': instance.start,
      'tokenCount': instance.tokenCount,
    };

_RelatedPhrase _$RelatedPhraseFromJson(Map<String, dynamic> json) =>
    _RelatedPhrase(
      phrase: json['phrase'] as String,
      kind: $enumDecode(_$RelatedPhraseKindEnumMap, json['kind']),
      partOfSpeech: json['partOfSpeech'] as String,
      meaning: json['meaning'] as String,
    );

Map<String, dynamic> _$RelatedPhraseToJson(_RelatedPhrase instance) =>
    <String, dynamic>{
      'phrase': instance.phrase,
      'kind': _$RelatedPhraseKindEnumMap[instance.kind]!,
      'partOfSpeech': instance.partOfSpeech,
      'meaning': instance.meaning,
    };

const _$RelatedPhraseKindEnumMap = {
  RelatedPhraseKind.phrasal: 'phrasal',
  RelatedPhraseKind.idiom: 'idiom',
};

_GrammarNote _$GrammarNoteFromJson(Map<String, dynamic> json) => _GrammarNote(
  source: json['source'] as String,
  shape: json['shape'] as String,
  points: (json['points'] as List<dynamic>)
      .map((e) => GrammarNotePoints.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GrammarNoteToJson(_GrammarNote instance) =>
    <String, dynamic>{
      'source': instance.source,
      'shape': instance.shape,
      'points': instance.points,
    };

_GrammarNotePoints _$GrammarNotePointsFromJson(Map<String, dynamic> json) =>
    _GrammarNotePoints(
      part: json['part'] as String,
      label: json['label'] as String,
      note: json['note'] as String,
    );

Map<String, dynamic> _$GrammarNotePointsToJson(_GrammarNotePoints instance) =>
    <String, dynamic>{
      'part': instance.part,
      'label': instance.label,
      'note': instance.note,
    };

_PassageSummary _$PassageSummaryFromJson(Map<String, dynamic> json) =>
    _PassageSummary(
      summary: json['summary'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      people: (json['people'] as List<dynamic>?)
          ?.map((e) => PassageSummaryPeople.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PassageSummaryToJson(_PassageSummary instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'points': instance.points,
      'people': instance.people,
    };

_PassageSummaryPeople _$PassageSummaryPeopleFromJson(
  Map<String, dynamic> json,
) => _PassageSummaryPeople(
  name: json['name'] as String,
  who: json['who'] as String,
);

Map<String, dynamic> _$PassageSummaryPeopleToJson(
  _PassageSummaryPeople instance,
) => <String, dynamic>{'name': instance.name, 'who': instance.who};

_EnglishDraft _$EnglishDraftFromJson(Map<String, dynamic> json) =>
    _EnglishDraft(
      english: json['english'] as String,
      vocab: (json['vocab'] as List<dynamic>)
          .map((e) => EnglishDraftVocab.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>)
          .map(
            (e) => EnglishDraftAlternatives.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$EnglishDraftToJson(_EnglishDraft instance) =>
    <String, dynamic>{
      'english': instance.english,
      'vocab': instance.vocab,
      'alternatives': instance.alternatives,
    };

_EnglishDraftVocab _$EnglishDraftVocabFromJson(Map<String, dynamic> json) =>
    _EnglishDraftVocab(en: json['en'] as String, hi: json['hi'] as String);

Map<String, dynamic> _$EnglishDraftVocabToJson(_EnglishDraftVocab instance) =>
    <String, dynamic>{'en': instance.en, 'hi': instance.hi};

_EnglishDraftAlternatives _$EnglishDraftAlternativesFromJson(
  Map<String, dynamic> json,
) => _EnglishDraftAlternatives(
  tone: $enumDecode(_$EnglishDraftAlternativesToneEnumMap, json['tone']),
  text: json['text'] as String,
);

Map<String, dynamic> _$EnglishDraftAlternativesToJson(
  _EnglishDraftAlternatives instance,
) => <String, dynamic>{
  'tone': _$EnglishDraftAlternativesToneEnumMap[instance.tone]!,
  'text': instance.text,
};

const _$EnglishDraftAlternativesToneEnumMap = {
  EnglishDraftAlternativesTone.formal: 'formal',
  EnglishDraftAlternativesTone.casual: 'casual',
  EnglishDraftAlternativesTone.direct: 'direct',
};

_Proofread _$ProofreadFromJson(Map<String, dynamic> json) => _Proofread(
  corrected: json['corrected'] as String,
  fixes: (json['fixes'] as List<dynamic>)
      .map((e) => ProofreadFixes.fromJson(e as Map<String, dynamic>))
      .toList(),
  alternatives: (json['alternatives'] as List<dynamic>)
      .map((e) => ProofreadAlternatives.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProofreadToJson(_Proofread instance) =>
    <String, dynamic>{
      'corrected': instance.corrected,
      'fixes': instance.fixes,
      'alternatives': instance.alternatives,
    };

_ProofreadAlternatives _$ProofreadAlternativesFromJson(
  Map<String, dynamic> json,
) => _ProofreadAlternatives(
  tone: $enumDecode(_$ProofreadAlternativesToneEnumMap, json['tone']),
  text: json['text'] as String,
);

Map<String, dynamic> _$ProofreadAlternativesToJson(
  _ProofreadAlternatives instance,
) => <String, dynamic>{
  'tone': _$ProofreadAlternativesToneEnumMap[instance.tone]!,
  'text': instance.text,
};

const _$ProofreadAlternativesToneEnumMap = {
  ProofreadAlternativesTone.formal: 'formal',
  ProofreadAlternativesTone.casual: 'casual',
  ProofreadAlternativesTone.concise: 'concise',
};

_ProofreadFixes _$ProofreadFixesFromJson(Map<String, dynamic> json) =>
    _ProofreadFixes(
      wrong: json['wrong'] as String,
      right: json['right'] as String,
      kind: $enumDecode(_$ProofreadFixesKindEnumMap, json['kind']),
      why: json['why'] as String,
    );

Map<String, dynamic> _$ProofreadFixesToJson(_ProofreadFixes instance) =>
    <String, dynamic>{
      'wrong': instance.wrong,
      'right': instance.right,
      'kind': _$ProofreadFixesKindEnumMap[instance.kind]!,
      'why': instance.why,
    };

const _$ProofreadFixesKindEnumMap = {
  ProofreadFixesKind.spelling: 'spelling',
  ProofreadFixesKind.grammar: 'grammar',
  ProofreadFixesKind.wording: 'wording',
};

_CoachTurn _$CoachTurnFromJson(Map<String, dynamic> json) => _CoachTurn(
  reply: json['reply'] as String,
  replyHindi: json['replyHindi'] as String,
  better: json['better'] == null
      ? null
      : CoachTurnBetter.fromJson(json['better'] as Map<String, dynamic>),
  closing: json['closing'] as bool?,
);

Map<String, dynamic> _$CoachTurnToJson(_CoachTurn instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'replyHindi': instance.replyHindi,
      'better': instance.better,
      'closing': instance.closing,
    };

_CoachTurnBetter _$CoachTurnBetterFromJson(Map<String, dynamic> json) =>
    _CoachTurnBetter(text: json['text'] as String, why: json['why'] as String);

Map<String, dynamic> _$CoachTurnBetterToJson(_CoachTurnBetter instance) =>
    <String, dynamic>{'text': instance.text, 'why': instance.why};

_ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => _ApiError(
  code: $enumDecode(_$ApiErrorCodeEnumMap, json['code']),
  message: json['message'] as String,
  suggestions: (json['suggestions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ApiErrorToJson(_ApiError instance) => <String, dynamic>{
  'code': _$ApiErrorCodeEnumMap[instance.code]!,
  'message': instance.message,
  'suggestions': instance.suggestions,
};

const _$ApiErrorCodeEnumMap = {
  ApiErrorCode.notFound: 'NOT_FOUND',
  ApiErrorCode.badRequest: 'BAD_REQUEST',
  ApiErrorCode.rateLimited: 'RATE_LIMITED',
  ApiErrorCode.upstreamFailed: 'UPSTREAM_FAILED',
  ApiErrorCode.internal: 'INTERNAL',
};
