// A practice conversation as it stands: what has been said, what is still
// waiting to be sent, and what the learner should say again at the end.
//
// Pure, so the whole shape of a conversation can be tested without a phone, a
// microphone or a server. The screen holds one of these and does nothing else
// with the state.

import 'package:arth/core/models/contracts.dart';

/// Who said a line.
enum Speaker { coach, learner }

/// One line of the conversation, as it is shown.
class CoachLine {
  const CoachLine({
    required this.speaker,
    required this.text,
    this.hindi,
    this.better,
  });

  final Speaker speaker;
  final String text;

  /// The coach's line in Hindi, under the English. Null on a learner's line.
  final String? hindi;

  /// A better way to have said it, on a learner's line that needed one.
  final CoachTurnBetter? better;

  CoachLine withBetter(CoachTurnBetter? b) =>
      CoachLine(speaker: speaker, text: text, hindi: hindi, better: b);
}

/// The scenes on offer. Ids match the server's; the labels are the app's,
/// because they have to exist in both languages.
enum CoachScene { interview, shop, doctor, introductions }

/// What the learner has to do next.
enum CoachStage {
  /// Waiting for the coach's opening line.
  opening,

  /// The coach has spoken; the learner's turn.
  theirTurn,

  /// Listening to the microphone.
  listening,

  /// The recogniser has produced something; the learner confirms or fixes it
  /// before it is sent. On-device recognition mishears Indian-accented English
  /// often enough that correcting a sentence the learner never said would be
  /// worse than not correcting at all.
  checking,

  /// Sent; waiting for the coach.
  waiting,

  /// The conversation is over.
  ended,
}

/// A conversation in progress.
class CoachSession {
  CoachSession(this.scene);

  final CoachScene scene;
  final List<CoachLine> lines = [];
  CoachStage stage = CoachStage.opening;

  /// What the recogniser heard, for the learner to confirm or correct.
  String draft = '';

  /// How many turns the learner has taken.
  int get replies => lines.where((l) => l.speaker == Speaker.learner).length;

  /// The learner's lines that came back with a better way to say them.
  List<CoachLine> get toPolish =>
      [for (final l in lines) if (l.speaker == Speaker.learner && l.better != null) l];

  /// The history to send, oldest first. The draft is not in it: it is sent
  /// separately as `said`, so the server can tell the new sentence from the
  /// conversation around it.
  List<({String role, String text})> get history => [
        for (final l in lines)
          (role: l.speaker == Speaker.coach ? 'coach' : 'learner', text: l.text),
      ];

  void addCoach(CoachTurn turn) {
    lines.add(CoachLine(speaker: Speaker.coach, text: turn.reply, hindi: turn.replyHindi));
    stage = (turn.closing ?? false) ? CoachStage.ended : CoachStage.theirTurn;
  }

  /// The learner's sentence, as they confirmed it.
  void addLearner(String text) {
    lines.add(CoachLine(speaker: Speaker.learner, text: text));
    draft = '';
    stage = CoachStage.waiting;
  }

  /// The coach's answer, which may carry a correction of the line just sent.
  void applyReply(CoachTurn turn) {
    final better = turn.better;
    if (better != null) {
      final last = lines.lastIndexWhere((l) => l.speaker == Speaker.learner);
      if (last >= 0) lines[last] = lines[last].withBetter(better);
    }
    addCoach(turn);
  }

  void heard(String text) {
    draft = text.trim();
    // Nothing heard is not a turn: send it and the coach answers silence.
    stage = draft.isEmpty ? CoachStage.theirTurn : CoachStage.checking;
  }

  void end() => stage = CoachStage.ended;
}
