import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/input/input_strategy.dart';
import 'package:gevurah/core/input/tap_swipe_strategy.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/game/boxing_game.dart';
import 'package:gevurah/game/components/effects.dart';
import 'package:gevurah/game/components/fighter.dart';
import 'package:gevurah/game/components/ring.dart';
import 'package:gevurah/game/components/shadow.dart';
import 'package:gevurah/game/fight_arena.dart';
import 'package:gevurah/game/fight_controller.dart';
import 'package:gevurah/game/hud/fight_hud.dart';
import 'package:gevurah/game/input/touch_layer.dart';
import 'package:gevurah/game/tuning.dart';
import 'package:gevurah/widgets/icon_chip.dart';
import 'package:gevurah/theme/app_theme.dart';
import 'package:gevurah/theme/tokens.dart';

import 'controller_test.dart' as ct;

void paint(void Function(Canvas) draw) {
  final PictureRecorder rec = PictureRecorder();
  draw(Canvas(rec));
  rec.endRecording().dispose();
}

Widget themed(Widget child, {TextDirection dir = TextDirection.ltr}) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(360, 720)),
    child: Directionality(textDirection: dir, child: AppTheme.forBrightness(brightness: Brightness.light, child: child)),
  );
}

const AppPalette pal = AppPalette.light;

void main() {
  group('Fighter', () {
    test('poses blend and return to idle', () {
      final Fighter f = Fighter(palette: pal)..size = Vector2(100, 200);
      expect(f.pose, FighterPose.idle);
      f.show(FighterPose.jab);
      expect(f.blend, 0);
      f.update(GameTuning.poseBlendMs / 2000);
      expect(f.blend, closeTo(0.5, 0.01));
      f.update(GameTuning.poseBlendMs / 2000);
      expect(f.blend, 1);
      expect(f.pose, FighterPose.jab);
      f.update(GameTuning.poseHoldMs / 1000);
      expect(f.pose, FighterPose.idle);
    });

    test('every pose renders and a stagger holds longer than a jab', () {
      final Fighter f = Fighter(palette: pal)..size = Vector2(100, 200);
      for (final FighterPose p in FighterPose.values) {
        f.show(p);
        f.update(1);
        paint(f.render);
      }
      f.show(FighterPose.stagger);
      f.update((GameTuning.poseHoldMs + 10) / 1000);
      expect(f.pose, FighterPose.stagger);
      f.show(FighterPose.guard, holdMs: 50);
      f.update(0.06);
      expect(f.pose, FighterPose.idle);
    });

    test('the glove positions move between idle and jab', () {
      final Fighter f = Fighter(palette: pal)..size = Vector2(100, 200);
      final List<double> idle = f.shape;
      f.show(FighterPose.jab);
      f.update(1);
      expect(f.shape[1], greaterThan(idle[1]));
    });

    test('Reduce Motion skips the blend', () {
      final Fighter f = Fighter(palette: pal, reduceMotion: true)..size = Vector2(100, 200);
      f.show(FighterPose.guard);
      expect(f.blend, 1);
      paint(f.render);
    });
  });

  group('Shadow', () {
    test('the same id gives the same shape and different ids differ', () {
      expect(ShadowShape.forId('fear'), ShadowShape.forId('fear'));
      final Set<ShadowShape> all = StruggleCatalog.all.map((s) => ShadowShape.forId(s.id)).toSet();
      expect(all.length, StruggleCatalog.all.length);
      for (final ShadowShape s in all) {
        expect(s.lobes, inInclusiveRange(3, 7));
      }
      expect(ShadowShape.forId('fear').hashCode, ShadowShape.forId('fear').hashCode);
    });

    test('the outline is a closed path of a sensible size', () {
      final Rect b = ShadowShape.forId('doubt').path(100).getBounds();
      expect(b.width, inInclusiveRange(100, 400));
      expect(b.height, inInclusiveRange(100, 400));
    });

    test('state flow: tell, lunge, flinch, down, dissolve, rise', () {
      final Shadow s = Shadow(shape: ShadowShape.forId('fear'), palette: pal)..size = Vector2(150, 300);
      expect(s.state, ShadowState.idle);
      s.tell(0.4);
      expect(s.state, ShadowState.tell);
      expect(s.tellProgress, 0.4);
      s.tell(2);
      expect(s.tellProgress, 1);
      s.lunge();
      expect(s.state, ShadowState.lunge);
      s.update(GameTuning.lungeMs / 1000 + 0.01);
      expect(s.state, ShadowState.idle);
      s.flinch();
      s.update(GameTuning.flinchMs / 1000 + 0.01);
      expect(s.state, ShadowState.idle);
      s.knockDown();
      s.update(5);
      expect(s.state, ShadowState.down);
      s.tell(0.5);
      s.lunge();
      s.flinch();
      expect(s.state, ShadowState.down);
      s.rise();
      s.update(GameTuning.riseMs / 1000 + 0.01);
      expect(s.state, ShadowState.idle);
      s.knockDown();
      s.dissolve();
      expect(s.opacity, 1);
      s.update(GameTuning.defeatLiftMs / 2000);
      expect(s.opacity, closeTo(0.5, 0.01));
      expect(s.dissolved, isFalse);
      s.update(GameTuning.defeatLiftMs / 1000);
      expect(s.opacity, 0);
      expect(s.dissolved, isTrue);
      s.tell(0.5);
      s.lunge();
      s.flinch();
      expect(s.state, ShadowState.dissolve);
      paint(s.render);
    });

    test('every state renders, with and without Reduce Motion', () {
      for (final bool reduce in <bool>[false, true]) {
        final Shadow s = Shadow(shape: ShadowShape.forId('pride'), palette: pal, reduceMotion: reduce)..size = Vector2(150, 300);
        paint(s.render);
        s.tell(0.7);
        s.update(0.1);
        paint(s.render);
        s.lunge();
        s.update(0.05);
        paint(s.render);
        s.flinch();
        s.update(0.05);
        paint(s.render);
        s.knockDown();
        paint(s.render);
        s.rise();
        s.update(0.1);
        paint(s.render);
        s.dissolve();
        s.update(0.2);
        paint(s.render);
        s.settle();
        expect(s.state, ShadowState.idle);
      }
    });
  });

  group('Effect and Ring', () {
    test('effects run to their duration and finish', () {
      for (final EffectKind k in EffectKind.values) {
        final Effect e = Effect(kind: k, color: pal.accent);
        expect(e.progress, 0);
        expect(e.finished, isFalse);
        e.update(0.1);
        paint(e.render);
        e.update(5);
        expect(e.finished, isTrue);
        expect(e.progress, 1);
        paint(e.render);
      }
    });

    test('Reduce Motion makes every effect a short flash', () {
      for (final EffectKind k in EffectKind.values) {
        expect(Effect(kind: k, color: pal.accent, reduceMotion: true).durationMs, GameTuning.reducedFlashMs);
      }
      expect(Effect(kind: EffectKind.stars, color: pal.accent).durationMs, GameTuning.starsMs);
      final Effect e = Effect(kind: EffectKind.impact, color: pal.accent, reduceMotion: true);
      e.update(0.05);
      paint(e.render);
    });

    test('the ring draws in both themes', () {
      for (final AppPalette p in <AppPalette>[AppPalette.light, AppPalette.dark]) {
        final Ring r = Ring(palette: p)..size = Vector2(360, 400);
        paint(r.render);
      }
    });
  });

  group('touch layer', () {
    testWidgets('a tap is stamped when the finger lands; a swipe when it passes the distance', (WidgetTester t) async {
      double now = 0;
      final List<RawGesture> got = <RawGesture>[];
      await t.pumpWidget(themed(SizedBox(width: 360, height: 640, child: FightTouchLayer(onGesture: got.add, nowMs: () => now, child: const SizedBox.expand()))));
      now = 100;
      final TestGesture tap = await t.startGesture(const Offset(100, 100));
      now = 180;
      await tap.up();
      expect(got.length, 1);
      expect(got.single.timestampMs, 100);
      expect(TapSwipeStrategy.isTap(got.single), isTrue);

      now = 300;
      final TestGesture swipe = await t.startGesture(const Offset(100, 200));
      now = 360;
      await swipe.moveBy(const Offset(60, 2));
      now = 400;
      await swipe.up();
      expect(got.length, 2);
      expect(got.last.timestampMs, 360);
      expect(TapSwipeStrategy.isSideSwipe(got.last), isTrue);
      expect(got.last.durationMs, 60);
    });

    testWidgets('a cancelled touch gives nothing and a small move is still a tap', (WidgetTester t) async {
      final List<RawGesture> got = <RawGesture>[];
      await t.pumpWidget(themed(SizedBox(width: 360, height: 640, child: FightTouchLayer(onGesture: got.add, nowMs: () => 7, child: const SizedBox.expand()))));
      final TestGesture g = await t.startGesture(const Offset(50, 50));
      await g.cancel();
      expect(got, isEmpty);
      final TestGesture small = await t.startGesture(const Offset(50, 50));
      await small.moveBy(const Offset(5, 3));
      await small.up();
      expect(got.length, 1);
      expect(TapSwipeStrategy.isTap(got.single), isTrue);
    });
  });

  group('HUD and arena', () {
    FightHudLabels labels() => FightHudLabels(
          resolve: 'Resolve',
          stamina: 'Stamina',
          weight: 'Weight',
          breath: 'Breath',
          pause: 'Pause',
          roundLabel: (int r) => 'Round $r of 3',
          moveName: (MoveKind k) => 'move-${k.name}',
        );

    testWidgets('shows the meters, the round and the Breath count, and Pause calls back', (WidgetTester t) async {
      final ct.Rig r = ct.Rig(skill: ct.Skill.never);
      int paused = 0;
      await t.pumpWidget(themed(SizedBox(width: 360, height: 700, child: FightHud(controller: r.controller, labels: labels(), locale: 'en', onPause: () => paused++))));
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Resolve'), findsOneWidget);
      expect(find.text('Stamina'), findsOneWidget);
      expect(find.text('Round 1 of 3'), findsOneWidget);
      expect(find.text('Breath'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await t.tap(find.byType(IconChip));
      expect(paused, 1);
    });

    testWidgets('Breath calls the controller and the tell shows only while waiting for a response', (WidgetTester t) async {
      final ct.Rig r = ct.Rig(skill: ct.Skill.never);
      await t.pumpWidget(themed(SizedBox(width: 360, height: 700, child: FightHud(controller: r.controller, labels: labels(), locale: 'en', onPause: () {}))));
      expect(find.textContaining('move-'), findsNothing);
      r.controller.begin();
      r.clock.now = GameTuning.resumeLeadMs + 1;
      r.controller.tick();
      await t.pump();
      expect(find.textContaining('move-'), findsOneWidget);
      r.clock.now += 100;
      r.controller.tick();
      await t.pump();
      await t.tap(find.text('Breath'));
      await t.pump();
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders with no bout and in right-to-left', (WidgetTester t) async {
      final ct.Rig r = ct.Rig(skill: ct.Skill.never);
      r.fight.abandon();
      await t.pumpWidget(themed(SizedBox(width: 360, height: 700, child: FightHud(controller: r.controller, labels: labels(), locale: 'ar', onPause: () {})), dir: TextDirection.rtl));
      expect(find.text('Weight'), findsNothing);
    });

    testWidgets('the arena runs the game, takes touches, and HUD buttons are not guard taps', (WidgetTester t) async {
      final ct.Rig r = ct.Rig();
      final BoxingGame game = BoxingGame(controller: r.controller, palette: pal, struggleId: StruggleCatalog.career.first.id);
      await t.pumpWidget(themed(SizedBox(
        width: 360,
        height: 700,
        child: FightArena(game: game, controller: r.controller, labels: labels(), locale: 'en', onPause: () {}),
      )));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(GameWidget<BoxingGame>), findsOneWidget);
      expect(t.takeException(), isNull);
      final List<RawGesture> seen = <RawGesture>[];
      r.controller.begin();
      await t.pump(const Duration(milliseconds: 100));
      expect(seen, isEmpty);
    });
  });

  group('BoxingGame', () {
    testWidgets('loads the world, lays it out and drives the controller each frame', (WidgetTester t) async {
      final ct.Rig r = ct.Rig(skill: ct.Skill.never);
      final BoxingGame game = BoxingGame(controller: r.controller, palette: pal, struggleId: StruggleCatalog.career.first.id);
      await t.pumpWidget(themed(SizedBox(width: 360, height: 640, child: GameWidget<BoxingGame>(game: game))));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(game.backgroundColor(), pal.bgPrimary);
      expect(game.fightWorld.size.x, 360);
      expect(game.fightWorld.fighter.position.x, closeTo(360 * GameTuning.playerX, 0.01));
      expect(game.fightWorld.shadow.position.x, closeTo(360 * GameTuning.shadowX, 0.01));
      r.controller.begin();
      r.clock.now = GameTuning.resumeLeadMs + 1;
      await t.pump(const Duration(milliseconds: 16));
      expect(r.controller.phase, ControllerPhase.waitingResponse);
      expect(game.fightWorld.shadow.state, ShadowState.tell);
      await t.pump(const Duration(milliseconds: 16));
      expect(t.takeException(), isNull);
    });

    testWidgets('the world reacts to a full bout: poses, effects and the defeat', (WidgetTester t) async {
      final ct.Rig r = ct.Rig();
      final BoxingGame game = BoxingGame(controller: r.controller, palette: pal, struggleId: StruggleCatalog.career.first.id);
      await t.pumpWidget(themed(SizedBox(width: 360, height: 640, child: GameWidget<BoxingGame>(game: game))));
      await t.pump();
      r.controller.begin();
      final Set<FighterPose> poses = <FighterPose>{};
      final Set<ShadowState> states = <ShadowState>{};
      bool effect = false;
      for (int i = 0; i < 30000 && !(r.fight.value?.finished ?? false); i++) {
        r.clock.now += 16;
        for (final ct.Tapish tp in List<ct.Tapish>.of(r.taps)) {
          if (r.clock.now >= tp.at) {
            r.taps.remove(tp);
            r.controller.gesture(RawGesture.tap(tp.at));
          }
        }
        await t.pump(const Duration(milliseconds: 16));
        poses.add(game.fightWorld.fighter.pose);
        states.add(game.fightWorld.shadow.state);
        effect = effect || game.fightWorld.children.whereType<Effect>().isNotEmpty;
      }
      expect(r.fight.value!.finished, isTrue);
      for (int i = 0; i < 100; i++) {
        r.clock.now += 16;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(poses.length, greaterThan(1));
      expect(states, containsAll(<ShadowState>[ShadowState.tell, ShadowState.lunge]));
      expect(effect, isTrue);
      expect(t.takeException(), isNull);
    });
  });
}
