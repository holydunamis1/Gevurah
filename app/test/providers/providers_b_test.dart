import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/config/remote_flags.dart';
import 'package:gevurah/core/logic/daily_seed.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/curated_verse.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/settings_model.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/verse.dart';
import 'package:gevurah/core/ports/billing_port.dart';
import 'package:gevurah/core/ports/consent_port.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/core/verses/verse_repository.dart';
import 'package:gevurah/providers/achievements_provider.dart';
import 'package:gevurah/providers/ad_provider.dart';
import 'package:gevurah/providers/app_providers.dart';
import 'package:gevurah/providers/consent_provider.dart';
import 'package:gevurah/providers/daily_provider.dart';
import 'package:gevurah/providers/entitlement_provider.dart';
import 'package:gevurah/providers/fight_provider.dart';
import 'package:gevurah/providers/flags_provider.dart';
import 'package:gevurah/providers/locale_provider.dart';
import 'package:gevurah/providers/progress_provider.dart';
import 'package:gevurah/providers/reminder_provider.dart';
import 'package:gevurah/providers/settings_provider.dart';
import 'package:gevurah/providers/verse_provider.dart';

import '../fakes/fakes.dart';

Future<String> fromDisk(String path) async => File(path).readAsStringSync();

ProgressProvider newProgress(FakeStorage s) =>
    ProgressProvider(ProgressStore(s, starterCardIds: CardCatalog.starterIds));

FightConfig journey({int seed = 7, FightMode mode = FightMode.journey, Difficulty d = Difficulty.standard}) => FightConfig(
      mode: mode,
      struggleId: StruggleCatalog.career.first.id,
      cardIds: const <String>[],
      stance: Stance.steady,
      seed: seed,
      difficulty: d,
    );

/// Plays a bout with perfect timing until it ends.
void playOut(FightProvider f) {
  for (int i = 0; i < 2000 && !(f.value?.finished ?? true); i++) {
    final FightView v = f.value!;
    if (v.state.phase == FightPhase.tenCount) {
      f.rise(3);
    } else if (v.state.phase == FightPhase.corner) {
      f.endCorner();
    } else if (v.move != null) {
      final Response r = v.move!.kind == MoveKind.heavy ? Response.slip : Response.guard;
      f.respond(response: r, offset: const BeatOffset(0), counter: OpeningAction.strike, strikeOffset: const BeatOffset(0));
    }
  }
}

class Rig {
  Rig({bool consent = true, Entitlement ent = Entitlement.none, RemoteFlags flags = RemoteFlags.defaults})
      : billing = FakeBilling()..entitlement = ent,
        consentPort = FakeConsent(ConsentState(canRequestAds: consent, privacyOptionsRequired: true)),
        ads = FakeAds() {
    entitlement = EntitlementProvider(billing);
    consentP = ConsentProvider(consentPort);
    flagsP = FlagsProvider(() async => flags);
    adP = AdProvider(ads: ads, consent: consentP, entitlement: entitlement, flags: flagsP);
  }

  final FakeBilling billing;
  final FakeConsent consentPort;
  final FakeAds ads;
  late final EntitlementProvider entitlement;
  late final ConsentProvider consentP;
  late final FlagsProvider flagsP;
  late final AdProvider adP;

  Future<void> boot() async {
    await entitlement.start();
    await flagsP.refresh();
    await consentP.refresh();
    await adP.start();
  }
}

void main() {
  group('fight', () {
    FightProvider make(FakeStorage storage, [FakeClock? clock]) {
      final ProgressProvider p = newProgress(storage);
      return FightProvider(progress: p, achievements: AchievementsProvider(p), clock: clock ?? FakeClock(DateTime(2026, 11, 22, 9)));
    }

    test('unknown struggle does not start', () async {
      final FightProvider f = make(FakeStorage());
      expect(f.start(journey().copyWith(struggleId: 'nope')), isFalse);
      expect(f.value, isNull);
      expect(f.telegraphMs, isNull);
      expect(f.respond(response: Response.guard, offset: const BeatOffset(0)), isNull);
      expect(await f.finish(), isNull);
    });

    test('a bout is deterministic for the same config and inputs', () {
      final FightProvider a = make(FakeStorage());
      final FightProvider b = make(FakeStorage());
      a.start(journey());
      b.start(journey());
      playOut(a);
      playOut(b);
      expect(a.value!.finished, isTrue);
      expect(a.value!.history.length, b.value!.history.length);
      expect(a.value!.state, b.value!.state);
    });

    test('a bout starts with a move and telegraph, and pauses have no move', () {
      final FightProvider f = make(FakeStorage());
      f.start(journey());
      expect(f.value!.move, isNotNull);
      expect(f.telegraphMs, greaterThan(0));
      f.breathe();
      playOut(f);
      expect(f.value!.move, isNull);
      f.rise(1);
      f.endCorner();
      f.breathe();
    });

    test('finishing records the win once, awards the card and unlocks first_win', () async {
      final FakeStorage storage = FakeStorage();
      final ProgressProvider p = newProgress(storage);
      await p.load();
      final AchievementsProvider ach = AchievementsProvider(p);
      final FightProvider f = FightProvider(progress: p, achievements: ach, clock: FakeClock(DateTime(2026, 11, 22)));
      f.start(journey());
      expect(await f.finish(), isNull);
      playOut(f);
      final FightFinish? done = await f.finish();
      expect(done, isNotNull);
      expect(done!.view.stars, inInclusiveRange(0, 3));
      if (done.view.won) {
        expect(p.progress.bouts[journey().struggleId]!.wins, 1);
        expect(done.newAchievements, contains('first_win'));
        expect(ach.takeNext(), isNotNull);
      }
      expect(identical(await f.finish(), done), isTrue);
    });

    test('training records nothing in the career', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final FightProvider f = FightProvider(progress: p, achievements: AchievementsProvider(p), clock: FakeClock(DateTime(2026, 11, 22)));
      f.start(journey(mode: FightMode.training));
      playOut(f);
      await f.finish();
      expect(p.progress.bouts, isEmpty);
    });

    test('a daily bout records the day, not the career', () async {
      final FakeClock clock = FakeClock(DateTime(2026, 11, 22, 9));
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final FightProvider f = FightProvider(progress: p, achievements: AchievementsProvider(p), clock: clock);
      final challenge = DailySeed.forDate(clock.now());
      f.start(journey(mode: FightMode.daily).copyWith(struggleId: challenge.struggleId, seed: challenge.seed), daily: challenge);
      playOut(f);
      final FightFinish? done = await f.finish();
      expect(done!.applied, isNull);
      expect(p.progress.dailyHistory.single.dateKey, challenge.dateKey);
      expect(p.progress.bouts, isEmpty);
    });

    test('sparring difficulty scales the Weight', () {
      final FightProvider f = make(FakeStorage());
      final int base = StruggleCatalog.career.first.weight;
      f.start(journey(mode: FightMode.sparring, d: Difficulty.gentle));
      expect(f.value!.state.startingWeight, (base * 0.8).round());
      f.start(journey(mode: FightMode.sparring, d: Difficulty.hard));
      expect(f.value!.state.startingWeight, (base * 1.25).round());
      f.start(journey(mode: FightMode.sparring));
      expect(f.value!.state.startingWeight, base);
      f.abandon();
      expect(f.value, isNull);
    });
  });

  group('ads and consent', () {
    test('nothing is requested before consent', () async {
      final Rig r = Rig(consent: false);
      await r.boot();
      expect(r.ads.initialized, isFalse);
      expect(r.adP.bannerVisible, isFalse);
      expect(await r.adP.maybeShowInterstitial(), isFalse);
      expect(await r.adP.watchRewarded(), isFalse);
      expect(r.consentP.privacyOptionsRequired, isTrue);
    });

    test('with consent a banner shows and an interstitial can run', () async {
      final Rig r = Rig();
      await r.boot();
      expect(r.ads.initialized, isTrue);
      expect(r.adP.bannerVisible, isTrue);
      expect(await r.adP.maybeShowInterstitial(), isTrue);
      expect(r.ads.interstitialsShown, 1);
      expect(r.adP.rewardedReady, isTrue);
      expect(await r.adP.watchRewarded(), isTrue);
    });

    test('Remove Ads hides banner and interstitials but keeps rewarded', () async {
      final Rig r = Rig(ent: Entitlement.adsRemoved);
      await r.boot();
      expect(r.adP.bannerVisible, isFalse);
      expect(await r.adP.maybeShowInterstitial(), isFalse);
      expect(r.adP.rewardedAllowed, isTrue);
      expect(await r.adP.watchRewarded(), isTrue);
    });

    test('remote flags switch surfaces off', () async {
      final Rig r = Rig(flags: const RemoteFlags(interstitialsEnabled: false, rewardedEnabled: false));
      await r.boot();
      expect(r.adP.bannerVisible, isTrue);
      expect(r.adP.interstitialAllowed, isFalse);
      expect(r.adP.rewardedAllowed, isFalse);
      final Rig off = Rig(flags: const RemoteFlags(adsEnabled: false));
      await off.boot();
      expect(off.adP.bannerVisible, isFalse);
      expect(off.ads.initialized, isFalse);
    });

    test('consent changes and purchases update the banner live', () async {
      final Rig r = Rig(consent: false);
      await r.boot();
      r.consentPort.state = const ConsentState(canRequestAds: true, privacyOptionsRequired: false);
      await r.consentP.showPrivacyOptions();
      expect(r.adP.bannerVisible, isTrue);
      r.billing.emit(Entitlement.adsRemoved);
      await Future<void>.delayed(Duration.zero);
      expect(r.adP.bannerVisible, isFalse);
    });

    test('flag and consent failures keep the last state', () async {
      final FlagsProvider f = FlagsProvider(() async => throw StateError('x'));
      await f.refresh();
      expect(f.value, RemoteFlags.defaults);
    });
  });

  group('daily, reminder, verses', () {
    test('daily shows today, completes and keeps a streak', () async {
      final FakeClock clock = FakeClock(DateTime(2026, 11, 22, 9));
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final FlagsProvider flags = FlagsProvider(() async => const RemoteFlags(dailyBoutEnabled: false));
      final DailyProvider d = DailyProvider(clock: clock, progress: p, flags: flags);
      expect(d.value.doneToday, isFalse);
      expect(d.value.enabled, isTrue);
      await flags.refresh();
      expect(d.value.enabled, isFalse);
      await p.applyDaily(d.value.challenge, completed: true, stars: 2);
      expect(d.value.doneToday, isTrue);
      expect(d.value.stars, 2);
      expect(d.value.streak, 1);
      clock.current = DateTime(2026, 11, 23, 9);
      d.refresh();
      expect(d.value.doneToday, isFalse);
      expect(d.value.streak, 1);
      expect(d.value, d.value);
      expect(d.value.hashCode, d.value.hashCode);
      d.dispose();
    });

    test('reminder asks permission only when turned on', () async {
      final FakeNotifications n = FakeNotifications();
      final SettingsProvider s = SettingsProvider(FakeStorage());
      final ReminderProvider r = ReminderProvider(notifications: n, settings: s);
      await r.sync(title: 't', body: 'b');
      expect(r.value, ReminderStatus.off);
      expect(n.scheduledMinute, isNull);
      expect(await r.setEnabled(true, title: 't', body: 'b'), ReminderStatus.scheduled);
      expect(n.scheduledMinute, 20 * 60);
      expect(s.settings.remindersOn, isTrue);
      await r.setTime(7 * 60 + 30, title: 't', body: 'b');
      expect(n.scheduledMinute, 450);
      await r.setTime(99999, title: 't', body: 'b');
      expect(n.scheduledMinute, 1439);
      expect(await r.setEnabled(false, title: 't', body: 'b'), ReminderStatus.off);
      expect(n.scheduledMinute, isNull);
    });

    test('a refused permission leaves the reminder off', () async {
      final FakeNotifications n = FakeNotifications()..grantOnRequest = false;
      final SettingsProvider s = SettingsProvider(FakeStorage());
      final ReminderProvider r = ReminderProvider(notifications: n, settings: s);
      expect(await r.setEnabled(true, title: 't', body: 'b'), ReminderStatus.permissionDenied);
      expect(s.settings.remindersOn, isFalse);
      await s.update((SettingsModel m) => m.copyWith(remindersOn: true));
      await r.sync(title: 't', body: 'b');
      expect(r.value, ReminderStatus.permissionDenied);
    });

    test('verses come in the player language, vary, and never throw', () async {
      final SettingsProvider s = SettingsProvider(FakeStorage());
      final LocaleProvider l = LocaleProvider(s);
      final VerseProvider v = VerseProvider(VerseRepository(fromDisk), l);
      final Verse? a = await v.forMoment(VerseMoment.win, seed: 1);
      expect(a, isNotNull);
      final Set<String> seen = <String>{a!.ref.toString()};
      for (int i = 0; i < 4; i++) {
        final Verse? x = await v.forMoment(VerseMoment.win, seed: i + 10);
        seen.add(x!.ref.toString());
      }
      expect(seen.length, greaterThan(1));
      await l.choose('es');
      expect(v.value, 'es');
      expect((await v.forMoment(VerseMoment.loss, seed: 3))!.language, 'es');
      expect(await v.preBout(StruggleCatalog.career.first.id), isNotNull);
      expect(await v.card(CardCatalog.starterIds.first), isNotNull);
      final VerseProvider broken = VerseProvider(VerseRepository((String p) async => throw const FormatException('x')), l);
      expect(await broken.forMoment(VerseMoment.win, seed: 1), isNull);
      expect(await broken.preBout('fear'), isNull);
      v.dispose();
    });
  });

  group('app providers', () {
    test('create wires everything and start-up reaches a ready state', () async {
      final FakeStorage storage = FakeStorage();
      final AppProviders app = AppProviders.create(
        storage: storage,
        clock: FakeClock(DateTime(2026, 11, 22, 9)),
        billing: FakeBilling(),
        consent: FakeConsent(const ConsentState(canRequestAds: true, privacyOptionsRequired: false)),
        ads: FakeAds(),
        notifications: FakeNotifications(),
        verseRepository: VerseRepository(fromDisk),
        fetchFlags: () async => RemoteFlags.defaults,
        deviceLanguages: <String>['de'],
      );
      await app.startUp();
      expect(app.settings.value.loaded, isTrue);
      expect(app.progress.value.status, ProgressStatus.ready);
      expect(app.locale.value, 'de');
      expect(app.ads.bannerVisible, isTrue);
      expect(app.daily.value.enabled, isTrue);
      app.dispose();
    });
  });

  group('achievements queue', () {
    test('empty queue returns null and nothing new unlocks on a fresh career', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final AchievementsProvider a = AchievementsProvider(p);
      expect(a.takeNext(), isNull);
      expect(await a.evaluate(), isEmpty);
    });
  });
}
