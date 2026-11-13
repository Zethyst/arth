// The phone's own speech recogniser, wrapped the way tts.dart wraps the
// synthesizer: initialised once, honest about not being available, and never
// throwing at a caller who just wants to know what was heard.
//
// Recognition is the platform's, not ours — Android's SpeechRecognizer and
// iOS's Speech framework. That keeps Say It Right free to run and working
// without an account, and it is why the score is about *which word* was heard
// rather than how the vowels sounded (see pronunciation.dart).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why listening is not possible, when it is not.
enum ListenBlock {
  /// The reader said no to the microphone.
  denied,

  /// The phone has no recogniser, or none for English.
  unavailable,
}

class ListeningService {
  ListeningService() : _speech = SpeechToText();

  final SpeechToText _speech;
  bool _ready = false;
  ListenBlock? _blocked;

  /// Null once [init] has found a working recogniser.
  ListenBlock? get blocked => _blocked;
  bool get ready => _ready && _blocked == null;
  bool get isListening => _speech.isListening;

  /// Asks for the microphone and checks a recogniser exists. Safe to call
  /// more than once; only the first does any work.
  Future<bool> init() async {
    if (_ready) return _blocked == null;
    _ready = true;
    try {
      final ok = await _speech.initialize(
        onError: (e) => debugPrint('speech: ${e.errorMsg}'),
      );
      if (!ok) {
        // Permission is what separates "the reader said no" from "this phone
        // has no recogniser" — two different things to tell them.
        _blocked = await _speech.hasPermission ? ListenBlock.unavailable : ListenBlock.denied;
      }
      return ok;
    } on Exception catch (e) {
      debugPrint('speech init: $e');
      _blocked = ListenBlock.unavailable;
      return false;
    }
  }

  /// Listens for one short utterance and returns what it heard, or '' if it
  /// heard nothing. [onPartial] fires as the words arrive, for a live caption.
  Future<String> listenOnce({
    Duration limit = const Duration(seconds: 5),
    ValueChanged<String>? onPartial,
  }) async {
    if (!await init()) return '';
    final done = Completer<String>();
    var last = '';
    try {
      await _speech.listen(
        onResult: (r) {
          last = r.recognizedWords;
          onPartial?.call(last);
          if (r.finalResult && !done.isCompleted) done.complete(last);
        },
        listenOptions: SpeechListenOptions(
          listenFor: limit,
          // A word is over quickly; waiting for a long pause makes the reader
          // sit looking at a live microphone after they have finished.
          pauseFor: const Duration(seconds: 2),
          localeId: 'en_US',
          cancelOnError: true,
        ),
      );
    } on Exception catch (e) {
      debugPrint('speech listen: $e');
      return '';
    }
    // listenFor is a hint, not a guarantee, on every platform.
    unawaited(
      Future<void>.delayed(limit + const Duration(seconds: 1)).then((_) {
        if (!done.isCompleted) done.complete(last);
      }),
    );
    return done.future;
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Exception catch (e) {
      debugPrint('speech stop: $e');
    }
  }
}
