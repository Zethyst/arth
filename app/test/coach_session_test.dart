// The shape of a practice conversation, without a phone or a server.
import 'package:arth/app/strings.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/features/tools/coach_session.dart';
import 'package:flutter_test/flutter_test.dart';

CoachTurn _turn(String reply, {String? better, String why = 'नियम।', bool closing = false}) => CoachTurn(
      reply: reply,
      replyHindi: 'हिंदी: $reply',
      better: better == null ? null : CoachTurnBetter(text: better, why: why),
      closing: closing,
    );

void main() {
  _errorWording();
  group('a conversation', () {
    test('opens with the coach, then it is the learner’s turn', () {
      final s = CoachSession(CoachScene.interview);
      expect(s.stage, CoachStage.opening);
      s.addCoach(_turn('Tell me about yourself.'));
      expect(s.stage, CoachStage.theirTurn);
      expect(s.lines.single.speaker, Speaker.coach);
      expect(s.lines.single.hindi, isNotNull);
    });

    test('what was heard waits to be confirmed before it is sent', () {
      // The whole point: a mishearing corrected as a mistake is worse than
      // no correction, so nothing is sent until the learner has seen it.
      final s = CoachSession(CoachScene.interview)
        ..addCoach(_turn('Hello.'))
        ..heard('I am working here since three years');
      expect(s.stage, CoachStage.checking);
      expect(s.draft, 'I am working here since three years');
      expect(s.replies, 0, reason: 'not a turn until it is confirmed');
    });

    test('hearing nothing is not a turn', () {
      final s = CoachSession(CoachScene.interview)
        ..addCoach(_turn('Hello.'))
        ..heard('   ');
      expect(s.stage, CoachStage.theirTurn);
      expect(s.draft, isEmpty);
    });

    test('the learner can send something other than what was heard', () {
      final s = CoachSession(CoachScene.interview)
        ..addCoach(_turn('Hello.'))
        ..heard('I am walking in marketing')
        ..addLearner('I am working in marketing');
      expect(s.lines.last.text, 'I am working in marketing');
      expect(s.draft, isEmpty);
      expect(s.stage, CoachStage.waiting);
    });

    test('a correction lands on the line it corrects, not the coach’s', () {
      final s = CoachSession(CoachScene.interview)
        ..addCoach(_turn('Tell me about yourself.'))
        ..addLearner('I am working in digital marketing since three years.')
        ..applyReply(_turn('Good. What did you work on?',
            better: 'I have been working in digital marketing for three years.'));
      final learner = s.lines.firstWhere((l) => l.speaker == Speaker.learner);
      expect(learner.better?.text, 'I have been working in digital marketing for three years.');
      expect(s.lines.last.speaker, Speaker.coach);
      expect(s.lines.last.better, isNull);
    });

    test('a turn with no correction leaves the line alone', () {
      final s = CoachSession(CoachScene.interview)
        ..addCoach(_turn('Hello.'))
        ..addLearner('Good morning.')
        ..applyReply(_turn('And you are?'));
      expect(s.lines.firstWhere((l) => l.speaker == Speaker.learner).better, isNull);
      expect(s.toPolish, isEmpty);
    });

    test('the history sent back is every line, in order, without the draft', () {
      final s = CoachSession(CoachScene.shop)
        ..addCoach(_turn('What are you looking for?'))
        ..addLearner('A shirt.')
        ..applyReply(_turn('What size?'))
        ..heard('Medium please');
      expect(s.history.map((t) => t.role), ['coach', 'learner', 'coach']);
      expect(s.history.map((t) => t.text), [
        'What are you looking for?',
        'A shirt.',
        'What size?',
      ]);
    });

    test('the end of the call is what to say again, and how much was said', () {
      final s = CoachSession(CoachScene.interview)
        ..addCoach(_turn('Tell me about yourself.'))
        ..addLearner('I am working since three years.')
        ..applyReply(_turn('I see.', better: 'I have been working for three years.'))
        ..addLearner('Thank you.')
        ..applyReply(_turn('Thanks for coming in.'));
      expect(s.replies, 2);
      expect(s.toPolish, hasLength(1));
      expect(s.toPolish.single.text, 'I am working since three years.');
    });

    test('the coach can close the conversation itself', () {
      final s = CoachSession(CoachScene.shop)..addCoach(_turn('Goodbye!', closing: true));
      expect(s.stage, CoachStage.ended);
    });

    test('ending it early still keeps what was said', () {
      final s = CoachSession(CoachScene.shop)
        ..addCoach(_turn('Hello.'))
        ..addLearner('Hello.')
        ..end();
      expect(s.stage, CoachStage.ended);
      expect(s.replies, 1);
    });
  });
}

/// A 404 means different things in different places, and saying the wrong one
/// sends you looking in the wrong place.
void _errorWording() {
  group('what a failure tells the reader', () {
    const en = AppStrings.en;

    test('a missing word is not in the dictionary', () {
      expect(en.errorFor('NOT_FOUND', 'x'), en.notFound);
    });

    test('a missing feature is not available yet, not missing from the dictionary', () {
      expect(en.errorForFeature('NOT_FOUND', 'x'), en.notAvailableYet);
      expect(en.errorForFeature('NOT_FOUND', 'x'), isNot(en.notFound));
    });

    test('every other code reads the same either way', () {
      for (final code in ['OFFLINE', 'RATE_LIMITED', 'UNAVAILABLE', 'INTERNAL']) {
        expect(en.errorForFeature(code, 'server said so'), en.errorFor(code, 'server said so'));
      }
    });
  });
}
