import 'package:arth/features/rating/rate_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 14, 21);

  bool ask({
    RatingState state = RatingState.open,
    DateTime? lastAskedAt,
    int streakDays = 0,
    Duration read = Duration.zero,
  }) =>
      shouldAskForRating(
        state: state,
        lastAskedAt: lastAskedAt,
        streakDays: streakDays,
        totalReadingMs: read.inMilliseconds,
        now: now,
      );

  test('a reader who has barely started is not asked', () {
    expect(ask(), isFalse);
    expect(ask(streakDays: 2, read: const Duration(minutes: 20)), isFalse);
  });

  test('either coming back for days or reading for long enough earns the ask', () {
    expect(ask(streakDays: kRateMinStreak), isTrue);
    expect(ask(read: kRateMinReading), isTrue);
    // One sitting of 45 minutes counts even on the first day.
    expect(ask(streakDays: 1, read: const Duration(hours: 2)), isTrue);
  });

  test('"not now" buys four months of quiet, and then the ask returns', () {
    final asked = now.subtract(kRateAskAgainAfter - const Duration(days: 1));
    expect(ask(streakDays: 30, lastAskedAt: asked), isFalse);
    expect(ask(streakDays: 30, lastAskedAt: asked.subtract(const Duration(days: 2))), isTrue);
  });

  test('a reader who has rated, or said never, is never asked again', () {
    expect(ask(state: RatingState.settled, streakDays: 365), isFalse);
    expect(ask(state: RatingState.settled, read: const Duration(days: 1)), isFalse);
  });
}
