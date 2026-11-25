import '../models/exchange_outcome.dart';
import '../models/exchange_record.dart';
import '../models/fight_config.dart';
import '../models/move_def.dart';
import '../models/stance.dart';

/// What a lesson asks the player to do.
enum LessonGoal { guard, slip, strike, combo, breath, readFake }

/// One guided Training lesson: a fixed, seeded mini-bout against a gentle
/// struggle with one goal. Lessons give no stars and change no progress.
class TrainingLesson {
  const TrainingLesson({required this.id, required this.struggleId, required this.seed, required this.goal, required this.target});

  final String id;
  final String struggleId;
  final int seed;
  final LessonGoal goal;

  /// How many times the goal must be met.
  final int target;

  /// The bout for this lesson. Timing assist is on so the lesson teaches the
  /// action, not the tightest window.
  FightConfig get config => FightConfig(
        mode: FightMode.training,
        struggleId: struggleId,
        cardIds: const <String>[],
        stance: Stance.steady,
        seed: seed,
        difficulty: Difficulty.gentle,
        timingAssist: true,
      );
}

/// The six lessons in teaching order, and the rule that counts progress.
abstract final class TrainingLessons {
  static const List<TrainingLesson> all = <TrainingLesson>[
    TrainingLesson(id: 'guard', struggleId: 'fear', seed: 101, goal: LessonGoal.guard, target: 3),
    TrainingLesson(id: 'slip', struggleId: 'anger', seed: 102, goal: LessonGoal.slip, target: 3),
    TrainingLesson(id: 'strike', struggleId: 'worry', seed: 103, goal: LessonGoal.strike, target: 3),
    TrainingLesson(id: 'combo', struggleId: 'worry', seed: 104, goal: LessonGoal.combo, target: 2),
    TrainingLesson(id: 'breath', struggleId: 'fear', seed: 105, goal: LessonGoal.breath, target: 1),
    TrainingLesson(id: 'fake', struggleId: 'doubt', seed: 106, goal: LessonGoal.readFake, target: 2),
  ];

  static TrainingLesson? byId(String id) {
    for (final TrainingLesson l in all) {
      if (l.id == id) {
        return l;
      }
    }
    return null;
  }

  /// The lesson after [id], or null after the last.
  static TrainingLesson? after(String id) {
    for (int i = 0; i < all.length - 1; i++) {
      if (all[i].id == id) {
        return all[i + 1];
      }
    }
    return null;
  }

  /// How far the player is: the count of exchanges that meet the goal, capped
  /// at the target. [breathUsed] is true once Breath has been used.
  static int progress(TrainingLesson lesson, List<ExchangeRecord> history, {required bool breathUsed}) {
    int n = 0;
    switch (lesson.goal) {
      case LessonGoal.breath:
        n = breathUsed ? 1 : 0;
      case LessonGoal.guard:
        n = history.where((ExchangeRecord r) => r.response == Response.guard && r.outcome.quality != Quality.miss).length;
      case LessonGoal.slip:
        n = history.where((ExchangeRecord r) => r.response == Response.slip && r.outcome.quality != Quality.miss).length;
      case LessonGoal.strike:
        n = history.where((ExchangeRecord r) => r.counter == OpeningAction.strike && r.outcome.damageDealt > 0).length;
      case LessonGoal.combo:
        n = history.where((ExchangeRecord r) => r.counter == OpeningAction.combo && r.outcome.damageDealt > 0).length;
      case LessonGoal.readFake:
        n = history.where((ExchangeRecord r) => r.move.kind == MoveKind.fake && r.response == Response.takeIt && r.outcome.damageTaken == 0).length;
    }
    return n > lesson.target ? lesson.target : n;
  }

  static bool isMet(TrainingLesson lesson, List<ExchangeRecord> history, {required bool breathUsed}) =>
      progress(lesson, history, breathUsed: breathUsed) >= lesson.target;
}
