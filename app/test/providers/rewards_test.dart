import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/progression_rules.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/ports/billing_port.dart';
import 'package:gevurah/core/ports/consent_port.dart';
import 'package:gevurah/providers/app_providers.dart';
import 'package:gevurah/providers/rewards_provider.dart';
import 'package:gevurah/screens/opponent_card_screen.dart';
import 'package:gevurah/screens/result_screen.dart';

import '../fakes/fakes.dart';
import '../screens/screens_test.dart' show Rigging, host, makeApp;

Progress withDays(List<String> done) => Progress.initial(starterCardIds: const <String>[]).copyWith(
      dailyHistory: <DailyRecord>[for (final String d in done) DailyRecord(dateKey: d, completed: true, stars: 2)],
    );

FightConfig config(FightMode mode, {int extraBreath = 0, int extraStamina = 0}) => FightConfig(
      mode: mode,
      struggleId: StruggleCatalog.career.first.id,
      cardIds: const <String>[],
      stance: Stance.steady,
      seed: 7,
      extraBreath: extraBreath,
      extraStamina: extraStamina,
    );

void main() {
  group('RewardsProvider.watch', () {
    test('earned, not earned, and unavailable', () async {
      final Rigging r = await makeApp();
      expect(r.app.rewards.offered, isTrue);
      expect(await r.app.rewards.watch(), RewardResult.earned);
      r.ads.rewardEarned = false;
      expect(await r.app.rewards.watch(), RewardResult.notEarned);
    });

    test('without consent no ad is offered or shown', () async {
      final Rigging r = await makeApp(consent: FakeConsent(const ConsentState(canRequestAds: false, privacyOptionsRequired: false)));
      expect(r.app.rewards.offered, isFalse);
      expect(await r.app.rewards.watch(), RewardResult.unavailable);
    });

    test('still offered after Remove Ads', () async {
      final FakeBilling billing = FakeBilling()..entitlement = Entitlement.adsRemoved;
      final Rigging r = await makeApp(billing: billing);
      expect(r.app.ads.bannerVisible, isFalse);
      expect(r.app.rewards.offered, isTrue);
    });
  });

  group('Daily restore rules', () {
    test('exactly one missed day after a completed day is restorable', () {
      expect(ProgressionRules.restorableDay(withDays(<String>['2026-11-20']), '2026-11-22'), '2026-11-21');
      expect(ProgressionRules.restorableDay(withDays(<String>['2026-11-20', '2026-11-21']), '2026-11-22'), isNull);
      expect(ProgressionRules.restorableDay(withDays(<String>['2026-11-18']), '2026-11-22'), isNull);
      expect(ProgressionRules.restorableDay(withDays(<String>[]), '2026-11-22'), isNull);
    });

    test('at most one restore every seven days', () {
      expect(ProgressionRules.restoreAllowed('', '2026-11-22'), isTrue);
      expect(ProgressionRules.restoreAllowed('2026-11-16', '2026-11-22'), isFalse);
      expect(ProgressionRules.restoreAllowed('2026-11-15', '2026-11-22'), isTrue);
    });

    test('restoring completes the day and keeps the streak going', () {
      final Progress p = ProgressionRules.restoreDay(withDays(<String>['2026-11-19', '2026-11-20']), '2026-11-21');
      expect(ProgressionRules.dailyStreak(p, '2026-11-22'), 3);
    });
  });

  group('restoring through an ad', () {
    test('earned: day restored and the date recorded; a second restore is refused', () async {
      final Rigging r = await makeApp(progress: withDays(<String>['2026-11-20']));
      expect(r.app.rewards.restorableDay, '2026-11-21');
      expect(await r.app.rewards.restoreDailyDay(), RewardResult.earned);
      expect(r.app.progress.progress.dailyHistory.any((DailyRecord d) => d.dateKey == '2026-11-21' && d.completed), isTrue);
      expect(r.app.settings.settings.dailyRestoredOn, '2026-11-22');
      expect(r.app.daily.value.streak, 2);
      expect(r.app.rewards.restorableDay, isNull);
      expect(await r.app.rewards.restoreDailyDay(), RewardResult.unavailable);
    });

    test('not earned: nothing changes', () async {
      final Rigging r = await makeApp(progress: withDays(<String>['2026-11-20']));
      r.ads.rewardEarned = false;
      expect(await r.app.rewards.restoreDailyDay(), RewardResult.notEarned);
      expect(r.app.progress.progress.dailyHistory, hasLength(1));
      expect(r.app.settings.settings.dailyRestoredOn, '');
    });
  });

  group('bout bonuses', () {
    test('extra Breath adds one charge; Daily and Training ignore it', () async {
      final Rigging r = await makeApp();
      r.app.fight.start(config(FightMode.journey, extraBreath: 1));
      expect(r.app.fight.value!.state.player.breathCharges, PlayerState.breathPerRound + 1);
      r.app.fight.start(config(FightMode.daily, extraBreath: 1, extraStamina: 20));
      expect(r.app.fight.value!.state.player, const PlayerState.initial());
      r.app.fight.start(config(FightMode.training, extraBreath: 1));
      expect(r.app.fight.value!.state.player, const PlayerState.initial());
    });

    test('extra Stamina raises the cap in Endurance only', () async {
      final Rigging r = await makeApp();
      r.app.fight.start(config(FightMode.endurance, extraStamina: 20));
      PlayerState p = r.app.fight.value!.state.player;
      expect((p.stamina, p.staminaCap), (120, 120));
      r.app.fight.start(config(FightMode.journey, extraStamina: 20));
      p = r.app.fight.value!.state.player;
      expect((p.stamina, p.staminaCap), (100, 100));
    });

    test('Breath refills to the raised cap', () async {
      final Rigging r = await makeApp();
      r.app.fight.start(config(FightMode.endurance, extraStamina: 20));
      r.app.fight.respond(response: Response.guard, offset: const BeatOffset(0));
      r.app.fight.breathe();
      expect(r.app.fight.value!.state.player.stamina, 120);
    });

    test('bonuses survive a config round trip; old saves read as none', () {
      final FightConfig c = config(FightMode.endurance, extraBreath: 1, extraStamina: 20).copyWith(isRetry: true);
      expect(FightConfig.fromJson(c.toJson()), c);
      final Map<String, Object?> plain = config(FightMode.journey).toJson();
      expect(plain.containsKey('extraBreath'), isFalse);
      expect(FightConfig.fromJson(plain).extraBreath, 0);
      const PlayerState p = PlayerState.boosted(extraStamina: 20);
      expect(PlayerState.fromJson(p.toJson()), p);
    });
  });

  group('screens', () {
    Widget card(AppProviders app, FightMode mode, List<String> log) => host(
          app,
          OpponentCardScreen(struggleId: StruggleCatalog.career.first.id, mode: mode, onStart: () => log.add('start'), onChangeCards: () {}, onBack: () {}),
        );

    testWidgets('the opponent card offers extra Breath and starts with it once earned', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(card(r.app, FightMode.journey, log));
      await t.pump();
      await t.pump();
      await t.scrollUntilVisible(find.text('Extra Breath for this bout'), 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.text('Extra Breath for this bout'));
      await t.pumpAndSettle();
      await t.tap(find.text('Extra Breath for this bout'));
      await t.pump();
      await t.pump();
      expect(find.text('Extra Breath ready'), findsOneWidget);
      await t.tap(find.text('Start bout'));
      expect(r.app.fight.value!.config.extraBreath, 1);
      expect(r.app.fight.value!.state.player.breathCharges, 2);
    });

    testWidgets('a failed ad grants nothing and says so', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.ads.rewardEarned = false;
      await t.pumpWidget(card(r.app, FightMode.journey, <String>[]));
      await t.pump();
      await t.pump();
      await t.scrollUntilVisible(find.text('Extra Breath for this bout'), 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.text('Extra Breath for this bout'));
      await t.pumpAndSettle();
      await t.tap(find.text('Extra Breath for this bout'));
      await t.pump();
      await t.pump();
      expect(find.text('No reward this time. The ad did not finish.'), findsOneWidget);
      expect(find.text('Extra Breath ready'), findsNothing);
    });

    testWidgets('no offers for the Daily Bout or without consent', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(card(r.app, FightMode.daily, <String>[]));
      await t.pump();
      await t.pump();
      expect(find.text('Extra Breath for this bout'), findsNothing);
      final Rigging none = await makeApp(consent: FakeConsent(const ConsentState(canRequestAds: false, privacyOptionsRequired: false)));
      await t.pumpWidget(card(none.app, FightMode.journey, <String>[]));
      await t.pump();
      await t.pump();
      expect(find.text('Extra Breath for this bout'), findsNothing);
    });

    testWidgets('after a loss one earned retry starts a fresh bout, and a retry cannot be retried', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      r.app.fight.start(config(FightMode.journey));
      for (int i = 0; i < 800 && !r.app.fight.value!.finished; i++) {
        final FightPhase phase = r.app.fight.value!.state.phase;
        if (phase == FightPhase.corner) {
          r.app.fight.endCorner();
        } else if (phase == FightPhase.tenCount) {
          r.app.fight.rise(0);
        } else {
          r.app.fight.respond(response: Response.takeIt, offset: const BeatOffset(0));
        }
      }
      expect(r.app.fight.value!.won, isFalse);
      final FightConfig lost = r.app.fight.value!.config;
      Widget result() => host(
            r.app,
            ResultScreen(onContinue: () {}, onTryAgain: () {}, onHome: () {}, onRetry: () => log.add('retry')),
          );
      await t.pumpWidget(result());
      await t.pump();
      await t.pump();
      await t.pump();
      expect(find.text('Try this bout again'), findsOneWidget);
      await t.tap(find.text('Try this bout again'));
      await t.pump();
      await t.pump();
      expect(log, <String>['retry']);
      final FightConfig again = r.app.fight.value!.config;
      expect(again.isRetry, isTrue);
      expect(again.seed, isNot(lost.seed));
      expect(again.struggleId, lost.struggleId);
      expect(again.cardIds, lost.cardIds);
    });
  });
}
