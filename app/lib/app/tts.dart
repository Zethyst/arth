// flutter_tts wrapper.
//
// On iOS the synthesizer follows the ringer switch unless the audio session is
// the "playback" category, so a phone on silent produced nothing — the most
// common reason "TTS doesn't work". Voices are checked once at startup so the
// speaker button can be hidden where a language truly is missing, but a
// language the platform reports in any spelling (en_US, en-US) still counts.
//
// The speaking coach asks for a voice by name rather than a language, because
// 'en-IN' alone leaves the platform to choose and it chooses the flattest
// voice it has. It also speaks a shade quicker and higher than the dictionary
// does: rate and pitch are the only life a synthesizer can be given, and a
// person in a conversation should not sound like a headword being read out.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  String? _english;
  String? _hindi;
  Map<String, String>? _englishVoice;
  bool _ready = false;

  bool get hasEnglish => _english != null;
  bool get hasHindi => _hindi != null;

  Future<void> init() async {
    if (_ready) return;
    try {
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }
      final langs = ((await _tts.getLanguages) as List<dynamic>? ?? const [])
          .map((l) => l.toString())
          .toList();
      String norm(String s) => s.toLowerCase().replaceAll('_', '-');
      String? pick(List<String> wanted, String prefix) {
        for (final w in wanted) {
          for (final l in langs) {
            if (norm(l) == norm(w)) return l;
          }
        }
        for (final l in langs) {
          if (norm(l).startsWith(prefix)) return l;
        }
        return null;
      }

      _english = pick(['en-IN', 'en-GB', 'en-US'], 'en');
      _hindi = pick(['hi-IN'], 'hi');
      // iOS ships Lekha (hi-IN) and several English voices; if the list came
      // back empty (some builds return [] until first use), assume both.
      if (langs.isEmpty && Platform.isIOS) {
        _english = 'en-US';
        _hindi = 'hi-IN';
      }
      final voices = ((await _tts.getVoices) as List<dynamic>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((v) => {
                for (final e in v.entries) e.key.toString(): e.value.toString(),
              })
          .where((v) => (v['name'] ?? '').isNotEmpty && (v['locale'] ?? '').isNotEmpty)
          .toList();
      _englishVoice = _best(voices, 'en-IN') ?? _best(voices, _english);
      await _tts.setVolume(1);
    } on Exception catch (e) {
      debugPrint('tts init failed: $e');
    }
    _ready = true;
  }

  /// A headword, or a sentence held up as the right way to say something:
  /// clear and unhurried, because it is there to be copied.
  Future<void> speakEnglish(String text) => _speak(_english ?? 'en-US', text);

  Future<void> speakHindi(String text) => _speak(_hindi ?? 'hi-IN', text);

  /// Somebody talking to you, not a dictionary reading at you.
  Future<void> speakCoach(String text) => _speak(
        _englishVoice?['locale'] ?? _english ?? 'en-US',
        text,
        voice: _englishVoice,
        rate: Platform.isIOS ? 0.54 : 0.52,
        pitch: 1.12,
      );

  /// The liveliest voice the platform has for [language], or null if it has
  /// none. Within a language an enhanced voice is worth having; on Android a
  /// network voice is not, since it falls silent offline and this is an
  /// offline dictionary.
  static Map<String, String>? _best(List<Map<String, String>> voices, String? language) {
    if (language == null) return null;
    String norm(String s) => s.toLowerCase().replaceAll('_', '-');
    final mine = [
      for (final v in voices)
        if (norm(v['locale']!) == norm(language)) v,
    ];
    if (mine.isEmpty) return null;
    int rank(Map<String, String> v) {
      if (Platform.isAndroid && v['name']!.toLowerCase().contains('network')) return 2;
      final q = (v['quality'] ?? '').toLowerCase();
      return q == 'enhanced' || q == 'premium' ? 0 : 1;
    }

    mine.sort((a, b) => rank(a).compareTo(rank(b)));
    return {'name': mine.first['name']!, 'locale': mine.first['locale']!};
  }

  /// Rate and pitch are set on every utterance, not once at startup: they
  /// belong to the thing being said. The language is set before the voice
  /// because setting a language clears the voice on both platforms, which is
  /// also what keeps an English voice from reading the Hindi.
  Future<void> _speak(
    String language,
    String text, {
    Map<String, String>? voice,
    double? rate,
    double pitch = 1,
  }) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(language);
      if (voice != null) await _tts.setVoice(voice);
      await _tts.setSpeechRate(rate ?? (Platform.isIOS ? 0.48 : 0.45));
      await _tts.setPitch(pitch);
      await _tts.speak(text);
    } on Exception catch (e) {
      debugPrint('tts speak failed: $e');
    }
  }

  Future<void> stop() => _tts.stop();
}
