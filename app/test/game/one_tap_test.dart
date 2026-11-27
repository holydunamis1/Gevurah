import 'package:gevurah/core/models/beat_offset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/input/input_strategy.dart';
import 'package:gevurah/core/input/one_tap_strategy.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/game/fight_controller.dart';
import 'package:gevurah/screens/ten_count_screen.dart';

import '../screens/screens_test.dart' show Rigging, host, makeApp;

class _Clock {
  double now = 0;
  double read() => now;
}

FightConfig easyConfig({int seed = 5}) => FightConfig(
      mode: FightMode.journey,
      struggleId: StruggleCatalog.career.first.id,
      cardIds: const <String>[],
      stance: Stance.steady,
      seed: seed,
      timingAssist: true,
      easy: true,
    );

void main() {
  group('OneTapStrategy', () {
    test('a tap or a swipe near the beat is a block with its offset', () {
      final OneTapStrategy s = OneTapStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.swipe(1030, dx: 120)), ResponseEvent(Response.guard, const BeatOffset(30)));
      expect(s.onResponseGesture(const RawGesture.tap(1040)), isNull, reason: 'one answer per move');
      expect(s.finishResponse()?.response, Response.guard);
    });

    test('a touch far from the beat is ignored', () {
      final OneTapStrategy s = OneTapStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.tap(100)), isNull);
      expect(s.finishResponse(), isNull);
    });

    test('there is nothing to do in the opening', () {
      final OneTapStrategy s = OneTapStrategy()..beginOpening(500);
      expect(s.onOpeningGesture(const RawGesture.tap(500)), isNull);
      expect(s.finishOpening(), isNull);
    });
  });

  group('the one-tap game', () {
    test('the easy flag survives a config round trip and is absent otherwise', () {
      expect(FightConfig.fromJson(easyConfig().toJson()), easyConfig());
      expect(easyConfig().copyWith(easy: false).toJson().containsKey('easy'), isFalse);
    });

    test('Stamina is effectively endless', () async {
      final Rigging r = await makeApp();
      r.app.fight.start(easyConfig());
      expect(r.app.fight.value!.state.player.stamina, greaterThan(PlayerState.maxStamina * 100));
    });

    test('a tap between exchanges is a free punch that never finishes the struggle', () async {
      final Rigging r = await makeApp();
      r.app.fight.start(easyConfig());
      final int start = r.app.fight.value!.state.weight;
      expect(start, StruggleCatalog.career.first.weight * 3);
      final _Clock clock = _Clock();
      final FightController c = FightController(fight: r.app.fight, input: OneTapStrategy(), nowMs: clock.read, autoCounter: true);
      int punches = 0;
      c.events.listen((FightEvent e) {
        if (e is PlayerPunched) {
          punches++;
        }
      });
      c.begin();
      for (int i = 0; i < 200; i++) {
        clock.now += 300;
        c.gesture(RawGesture.tap(clock.now));
        c.tick();
        if (c.phase != ControllerPhase.lead) {
          break;
        }
      }
      expect(punches, greaterThan(0));
      expect(r.app.fight.value!.state.weight, lessThan(start));
      expect(r.app.fight.punch(100000), isTrue);
      expect(r.app.fight.value!.state.weight, 1);
      expect(r.app.fight.punch(3), isFalse, reason: 'the last blow is a counter');
      expect(r.app.fight.value!.finished, isFalse);
    });

    test('taps alone win a bout: blocks bring automatic counters', () async {
      final Rigging r = await makeApp();
      r.app.fight.start(easyConfig());
      final _Clock clock = _Clock();
      final List<double> taps = <double>[];
      final FightController c = FightController(fight: r.app.fight, input: OneTapStrategy(), nowMs: clock.read, autoCounter: true);
      c.events.listen((FightEvent e) {
        if (e is TelegraphStarted) {
          taps.add(clock.now + e.telegraphMs);
        } else if (e is FightPaused) {
          if (e.reason == PauseReason.corner) {
            r.app.fight.endCorner();
            c.resume();
          } else if (e.reason == PauseReason.tenCount) {
            r.app.fight.rise(3);
            c.resume();
          }
        }
      });
      c.begin();
      for (int i = 0; i < 400000; i++) {
        clock.now += 8;
        c.tick();
        for (final double at in List<double>.of(taps)) {
          if (clock.now >= at) {
            taps.remove(at);
            c.gesture(RawGesture.tap(at));
          }
        }
        if (r.app.fight.value!.finished && c.phase == ControllerPhase.paused) {
          break;
        }
      }
      final history = r.app.fight.value!.history;
      expect(r.app.fight.value!.finished, isTrue);
      expect(history.any((ExchangeRecord e) => e.counter != OpeningAction.none), isTrue, reason: 'a good block throws a counter by itself');
      expect(r.app.fight.value!.won, isTrue);
      await c.dispose();
    });
  });

  testWidgets('the one-tap ten-count has a single button that stands the player up', (WidgetTester t) async {
    final Rigging r = await makeApp();
    final List<int> rose = <int>[];
    await t.pumpWidget(host(r.app, TenCountScreen(simple: true, onRise: rose.add)));
    await t.pump();
    expect(find.text('Tap'), findsNothing);
    await t.tap(find.text('Stand up'));
    expect(rose, <int>[TenCountScreen.targetTaps]);
  });
}
