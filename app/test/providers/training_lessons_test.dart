import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/catalog/training_lessons.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/settings_model.dart';
import 'package:gevurah/providers/fight_provider.dart';

import '../screens/screens_test.dart' show Rigging, makeApp;

const BeatOffset perfect = BeatOffset(0);

/// A scripted player who knows the lesson: the right answer to every move, and
/// the opening action the lesson asks for. Returns true if the goal was met
/// before the bout ended.
bool runLesson(Rigging r, TrainingLesson lesson) {
  final FightProvider fight = r.app.fight;
  expect(fight.start(lesson.config), isTrue);
  bool breathUsed = false;
  for (int i = 0; i < 400; i++) {
    final FightView v = fight.value!;
    if (TrainingLessons.isMet(lesson, v.history, breathUsed: breathUsed)) {
      return true;
    }
    if (v.finished) {
      return false;
    }
    final FightPhase phase = v.state.phase;
    if (phase == FightPhase.corner) {
      fight.endCorner();
    } else if (phase == FightPhase.tenCount) {
      fight.rise(3);
    } else if (lesson.goal == LessonGoal.breath) {
      fight.breathe();
      breathUsed = true;
    } else {
      final MoveKind kind = v.move!.kind;
      final Response answer = switch (kind) {
        MoveKind.heavy => lesson.goal == LessonGoal.guard ? Response.guard : Response.slip,
        MoveKind.fake => lesson.goal == LessonGoal.readFake ? Response.takeIt : Response.guard,
        _ => lesson.goal == LessonGoal.slip ? Response.slip : Response.guard,
      };
      final OpeningAction counter = switch (lesson.goal) {
        LessonGoal.strike => OpeningAction.strike,
        LessonGoal.combo => OpeningAction.combo,
        _ => OpeningAction.none,
      };
      fight.respond(response: answer, offset: perfect, counter: counter, strikeOffset: counter == OpeningAction.none ? null : perfect);
    }
  }
  return false;
}

void main() {
  group('lesson catalog', () {
    test('six lessons in teaching order, each against a known struggle, ids unique', () {
      expect(TrainingLessons.all.map((TrainingLesson l) => l.goal), LessonGoal.values);
      expect(TrainingLessons.all.map((TrainingLesson l) => l.id).toSet(), hasLength(6));
      for (final TrainingLesson l in TrainingLessons.all) {
        expect(StruggleCatalog.byId(l.struggleId), isNotNull, reason: l.id);
        expect(l.target, greaterThan(0));
        expect(l.config.mode, FightMode.training);
        expect(l.config.difficulty, Difficulty.gentle);
        expect(l.config.timingAssist, isTrue);
      }
    });

    test('after() walks the order and ends after the last', () {
      expect(TrainingLessons.after('guard')?.id, 'slip');
      expect(TrainingLessons.after('fake'), isNull);
      expect(TrainingLessons.byId('combo')?.goal, LessonGoal.combo);
      expect(TrainingLessons.byId('nope'), isNull);
    });

    test('a bot that does nothing never meets any goal', () {
      for (final TrainingLesson l in TrainingLessons.all) {
        expect(TrainingLessons.progress(l, const <ExchangeRecord>[], breathUsed: false), 0, reason: l.id);
        expect(TrainingLessons.isMet(l, const <ExchangeRecord>[], breathUsed: false), isFalse, reason: l.id);
      }
      expect(TrainingLessons.isMet(TrainingLessons.byId('breath')!, const <ExchangeRecord>[], breathUsed: true), isTrue);
    });
  });

  group('every lesson can be completed', () {
    for (final TrainingLesson lesson in TrainingLessons.all) {
      test(lesson.id, () async {
        final Rigging r = await makeApp();
        expect(runLesson(r, lesson), isTrue);
      });
    }
  });

  test('lessons never change the saved career', () async {
    final Rigging r = await makeApp();
    final before = r.app.progress.progress;
    for (final TrainingLesson lesson in TrainingLessons.all) {
      runLesson(r, lesson);
      await r.app.fight.finish();
    }
    expect(r.app.progress.progress, before);
  });

  test('completed lessons are saved in settings and survive a round trip', () {
    const SettingsModel m = SettingsModel(trainingDone: <String>['guard', 'slip']);
    expect(SettingsModel.fromJson(m.toJson()), m);
    expect(SettingsModel.fromJson(m.toJson()).trainingDone, <String>['guard', 'slip']);
    expect(SettingsModel.fromJson(<String, Object?>{...m.toJson()}..remove('trainingDone')).trainingDone, isEmpty);
    expect(m == m.copyWith(trainingDone: <String>['guard']), isFalse);
  });
}
