// When the day's idiom should arrive, and which one it is.
//
// Pure, so the schedule can be tested without a phone: the notification layer
// in app/reminders.dart takes these slots and hands them to the plugin. The
// idioms are already on the device, so none of this needs an account, a
// server, or a connection.

import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_selection.dart';

/// Sensible default: late evening, when a reader is likely to be reading.
const int kDefaultIdiomHour = 20;

/// How many days ahead to schedule. iOS caps an app at 64 pending
/// notifications and the card reminders want their share, so a fortnight is
/// plenty — the app reschedules every time it runs.
const int kIdiomDaysAhead = 14;

/// One day's idiom notification.
typedef IdiomSlot = ({DateTime at, IdiomRow idiom});

/// The next [days] daily idioms, starting with the next [hour] that has not
/// already passed.
///
/// Each day's idiom is the first of that day's set, so the notification and
/// the Today's 10 screen agree about what today's idiom is.
List<IdiomSlot> planDailyIdioms({
  required List<IdiomRow> idioms,
  required DateTime now,
  int hour = kDefaultIdiomHour,
  int days = kIdiomDaysAhead,
}) {
  if (idioms.isEmpty) return const [];
  var first = DateTime(now.year, now.month, now.day, hour);
  if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
  final out = <IdiomSlot>[];
  for (var i = 0; i < days; i++) {
    final at = first.add(Duration(days: i));
    final set = dailySet(idioms, at);
    if (set.isEmpty) break;
    out.add((at: at, idiom: set.first));
  }
  return out;
}
