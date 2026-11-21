import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/ports/consent_port.dart';
import 'package:gevurah/platform/ad_service.dart';
import 'package:gevurah/platform/ad_unit_ids.dart';
import 'package:gevurah/platform/consent_service.dart';

import '../fakes/fakes.dart';

class FakeUmp implements UmpDriver {
  bool updateOk = true;
  bool updateThrows = false;
  bool formShown = false;
  bool formThrows = false;
  bool canRequest = false;
  bool optionsRequired = false;
  bool readThrows = false;
  bool hang = false;
  int optionsShown = 0;
  bool acceptOnForm = true;

  @override
  Future<bool> requestInfoUpdate() async {
    if (hang) {
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    if (updateThrows) {
      throw StateError('x');
    }
    return updateOk;
  }

  @override
  Future<void> loadAndShowFormIfRequired() async {
    if (formThrows) {
      throw StateError('x');
    }
    formShown = true;
    if (acceptOnForm) {
      canRequest = true;
    }
  }

  @override
  Future<bool> canRequestAds() async {
    if (readThrows) {
      throw StateError('x');
    }
    return canRequest;
  }

  @override
  Future<bool> privacyOptionsRequired() async => optionsRequired;

  @override
  Future<void> showPrivacyOptions() async {
    optionsShown++;
    canRequest = false;
  }
}

class FakeAdsDriver implements AdsDriver {
  bool initThrows = false;
  bool loadOk = true;
  bool showOk = true;
  bool rewardEarned = true;
  int inits = 0;
  final List<String> loaded = <String>[];
  int shownInterstitials = 0;

  @override
  Future<void> initialize() async {
    inits++;
    if (initThrows) {
      throw StateError('no sdk');
    }
  }

  @override
  Future<bool> loadInterstitial(String unitId) async {
    loaded.add(unitId);
    return loadOk;
  }

  @override
  Future<bool> showInterstitial() async {
    shownInterstitials++;
    return showOk;
  }

  @override
  Future<bool> loadRewarded(String unitId) async {
    loaded.add(unitId);
    return loadOk;
  }

  @override
  Future<bool> showRewarded() async => rewardEarned;
}

void main() {
  group('ConsentService (the section 7 matrix)', () {
    test('no prior answer in a regulated region: the form shows and ads wait for it', () async {
      final FakeUmp ump = FakeUmp()..acceptOnForm = false;
      final ConsentState s = await ConsentService(driver: ump).refresh();
      expect(ump.formShown, true);
      expect(s.canRequestAds, false);
    });

    test('the player agrees on the form: ads may be requested', () async {
      final FakeUmp ump = FakeUmp();
      expect((await ConsentService(driver: ump).refresh()).canRequestAds, true);
    });

    test('outside regulated regions the platform allows ads at once', () async {
      final FakeUmp ump = FakeUmp()..canRequest = true;
      expect((await ConsentService(driver: ump).refresh()).canRequestAds, true);
    });

    test('offline: saved consent still allows ads and no form is shown', () async {
      final FakeUmp ump = FakeUmp()
        ..updateOk = false
        ..canRequest = true;
      final ConsentState s = await ConsentService(driver: ump).refresh();
      expect(s.canRequestAds, true);
      expect(ump.formShown, false);
    });

    test('offline with nothing saved: no ads', () async {
      final FakeUmp ump = FakeUmp()..updateOk = false;
      expect((await ConsentService(driver: ump).refresh()).canRequestAds, false);
    });

    test('a hanging or throwing refresh falls back to the saved state', () async {
      final FakeUmp slow = FakeUmp()
        ..hang = true
        ..canRequest = true;
      expect((await ConsentService(driver: slow, timeout: const Duration(milliseconds: 20)).refresh()).canRequestAds, true);
      final FakeUmp broken = FakeUmp()
        ..updateThrows = true
        ..canRequest = true;
      expect((await ConsentService(driver: broken).refresh()).canRequestAds, true);
      final FakeUmp formBroken = FakeUmp()
        ..formThrows = true
        ..canRequest = true;
      expect((await ConsentService(driver: formBroken).refresh()).canRequestAds, true);
    });

    test('unreadable platform state means no ads', () async {
      final FakeUmp ump = FakeUmp()..readThrows = true;
      expect(await ConsentService(driver: ump).refresh(), ConsentState.unknown);
    });

    test('privacy options are reported and withdrawal is re-read at once', () async {
      final FakeUmp ump = FakeUmp()
        ..canRequest = true
        ..optionsRequired = true;
      final ConsentService s = ConsentService(driver: ump);
      expect((await s.refresh()).privacyOptionsRequired, true);
      final ConsentState after = await s.showPrivacyOptions();
      expect(ump.optionsShown, 1);
      expect(after.canRequestAds, false);
    });

    test('ConsentState has equality and text', () {
      expect(const ConsentState(canRequestAds: true, privacyOptionsRequired: false),
          const ConsentState(canRequestAds: true, privacyOptionsRequired: false));
      expect(ConsentState.unknown.toString(), contains('canRequestAds: false'));
      expect(ConsentState.unknown.hashCode, ConsentState.unknown.hashCode);
    });
  });

  group('AdService', () {
    late FakeAdsDriver driver;
    late FakeClock clock;
    late bool consent;
    late bool removed;
    late FakeLog log;

    AdService make() => AdService(
          driver: driver,
          unitIds: AdUnitIds.androidTest,
          canRequestAds: () => consent,
          adsRemoved: () => removed,
          clock: clock,
          log: log,
        );

    setUp(() {
      driver = FakeAdsDriver();
      clock = FakeClock(DateTime(2026, 11, 21, 12));
      consent = true;
      removed = false;
      log = FakeLog();
    });

    test('nothing starts before consent allows it', () async {
      consent = false;
      final AdService s = make();
      await s.initialize();
      await s.loadInterstitial();
      await s.loadRewarded();
      expect(driver.inits, 0);
      expect(driver.loaded, isEmpty);
      expect(s.interstitialReady, false);
      expect(s.rewardedReady, false);
    });

    test('the SDK starts once, after consent', () async {
      final AdService s = make();
      await s.loadInterstitial();
      await s.loadInterstitial();
      expect(driver.inits, 1);
      expect(driver.loaded, <String>[AdUnitIds.androidTest.interstitial, AdUnitIds.androidTest.interstitial]);
    });

    test('an SDK that fails to start means no ad and a log line, never an exception', () async {
      driver.initThrows = true;
      final AdService s = make();
      await s.loadInterstitial();
      await s.loadRewarded();
      expect(s.interstitialReady, false);
      expect(s.rewardedReady, false);
      expect(log.lines, isNotEmpty);
    });

    test('Remove Ads blocks interstitials but not rewarded ads', () async {
      removed = true;
      final AdService s = make();
      await s.loadInterstitial();
      expect(driver.loaded, isEmpty);
      await s.loadRewarded();
      expect(s.rewardedReady, true);
      expect(await s.showRewarded(), true);
    });

    test('the 10-minute gap counts from app start, then from the last ad', () async {
      final AdService s = make();
      await s.loadInterstitial();
      expect(await s.showInterstitial(), false, reason: 'too soon after start');
      clock.current = clock.current.add(const Duration(minutes: 10));
      await s.loadInterstitial();
      expect(await s.showInterstitial(), true);
      await s.loadInterstitial();
      clock.current = clock.current.add(const Duration(minutes: 9, seconds: 59));
      expect(await s.showInterstitial(), false);
      clock.current = clock.current.add(const Duration(seconds: 2));
      expect(await s.showInterstitial(), true);
      expect(driver.shownInterstitials, 2);
    });

    test('showing needs a loaded ad and still-valid consent and entitlement', () async {
      final AdService s = make();
      clock.current = clock.current.add(const Duration(minutes: 30));
      expect(await s.showInterstitial(), false, reason: 'nothing loaded');
      await s.loadInterstitial();
      consent = false;
      expect(await s.showInterstitial(), false, reason: 'consent withdrawn');
      consent = true;
      removed = true;
      expect(await s.showInterstitial(), false, reason: 'ads removed after loading');
    });

    test('a failed load or show only means no ad', () async {
      driver.loadOk = false;
      final AdService s = make();
      await s.loadInterstitial();
      expect(s.interstitialReady, false);
      driver.loadOk = true;
      driver.showOk = false;
      clock.current = clock.current.add(const Duration(minutes: 30));
      await s.loadInterstitial();
      expect(await s.showInterstitial(), false);
      expect(s.interstitialReady, false);
    });

    test('a rewarded ad pays only when the reward was earned, and only once per load', () async {
      final AdService s = make();
      await s.loadRewarded();
      driver.rewardEarned = false;
      expect(await s.showRewarded(), false);
      expect(await s.showRewarded(), false, reason: 'already used');
      await s.loadRewarded();
      driver.rewardEarned = true;
      expect(await s.showRewarded(), true);
    });
  });

  group('AdUnitIds', () {
    test('samples by platform, production only for release when supplied', () {
      expect(AdUnitIds.select(android: true), AdUnitIds.androidTest);
      expect(AdUnitIds.select(android: false), AdUnitIds.iosTest);
      const AdUnitIds prod = AdUnitIds(banner: 'b', interstitial: 'i', rewarded: 'r');
      expect(AdUnitIds.select(android: true, production: prod), AdUnitIds.androidTest);
      expect(AdUnitIds.select(android: true, release: true), AdUnitIds.androidTest);
      expect(AdUnitIds.select(android: true, release: true, production: prod), prod);
    });

    test('every sample id is a Google sample publisher id', () {
      for (final AdUnitIds ids in <AdUnitIds>[AdUnitIds.androidTest, AdUnitIds.iosTest]) {
        for (final String id in <String>[ids.banner, ids.interstitial, ids.rewarded]) {
          expect(id, startsWith('ca-app-pub-3940256099942544/'));
        }
      }
    });
  });
}
