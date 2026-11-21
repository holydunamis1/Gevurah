import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/config/app_config.dart';
import '../core/ports/ads_port.dart';
import '../core/ports/clock_port.dart';
import '../core/ports/log_port.dart';
import 'ad_unit_ids.dart';

/// The calls the service needs from the ad SDK.
abstract class AdsDriver {
  Future<void> initialize();

  /// True when an interstitial loaded.
  Future<bool> loadInterstitial(String unitId);

  /// True when the ad was shown and closed.
  Future<bool> showInterstitial();

  Future<bool> loadRewarded(String unitId);

  /// True when the player earned the reward.
  Future<bool> showRewarded();
}

class GoogleAdsDriver implements AdsDriver {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<bool> loadInterstitial(String unitId) {
    final Completer<bool> done = Completer<bool>();
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitial = ad;
          done.complete(true);
        },
        onAdFailedToLoad: (LoadAdError error) => done.complete(false),
      ),
    );
    return done.future;
  }

  @override
  Future<bool> showInterstitial() {
    final InterstitialAd? ad = _interstitial;
    _interstitial = null;
    if (ad == null) {
      return Future<bool>.value(false);
    }
    final Completer<bool> done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd a) {
        a.dispose();
        done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd a, AdError error) {
        a.dispose();
        done.complete(false);
      },
    );
    ad.show();
    return done.future;
  }

  @override
  Future<bool> loadRewarded(String unitId) {
    final Completer<bool> done = Completer<bool>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewarded = ad;
          done.complete(true);
        },
        onAdFailedToLoad: (LoadAdError error) => done.complete(false),
      ),
    );
    return done.future;
  }

  @override
  Future<bool> showRewarded() {
    final RewardedAd? ad = _rewarded;
    _rewarded = null;
    if (ad == null) {
      return Future<bool>.value(false);
    }
    final Completer<bool> done = Completer<bool>();
    bool earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd a) {
        a.dispose();
        done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd a, AdError error) {
        a.dispose();
        done.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (AdWithoutView view, RewardItem reward) => earned = true);
    return done.future;
  }
}

/// Interstitial and rewarded ads. Nothing starts until consent allows it. An
/// interstitial also needs ads not removed and the 10-minute gap; a rewarded
/// ad stays available after Remove Ads. Any failure only means no ad.
class AdService implements AdsPort {
  AdService({
    required this.driver,
    required this.unitIds,
    required this.canRequestAds,
    required this.adsRemoved,
    this.clock = const SystemClock(),
    this.log,
    this.gap = AppConfig.interstitialGap,
  }) : _startedAt = clock.now();

  final AdsDriver driver;
  final AdUnitIds unitIds;

  /// Reads the consent gate and the Remove Ads entitlement at the moment of use.
  final bool Function() canRequestAds;
  final bool Function() adsRemoved;
  final ClockPort clock;
  final LogPort? log;
  final Duration gap;

  final DateTime _startedAt;
  DateTime? _lastInterstitial;
  bool _initialized = false;
  bool _interstitialReady = false;
  bool _rewardedReady = false;

  @override
  Future<void> initialize() async {
    if (_initialized || !canRequestAds()) {
      return;
    }
    try {
      await driver.initialize();
      _initialized = true;
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Ad SDK failed to start', error: e);
    }
  }

  bool get _interstitialAllowed => canRequestAds() && !adsRemoved();

  @override
  bool get interstitialReady => _interstitialReady;

  @override
  bool get rewardedReady => _rewardedReady;

  @override
  Future<void> loadInterstitial() async {
    if (!_interstitialAllowed) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      _interstitialReady = await driver.loadInterstitial(unitIds.interstitial);
    } on Object catch (e) {
      _interstitialReady = false;
      log?.log(LogLevel.warning, 'Interstitial failed to load', error: e);
    }
  }

  @override
  Future<bool> showInterstitial() async {
    if (!_interstitialReady || !_interstitialAllowed) {
      return false;
    }
    final DateTime now = clock.now();
    if (now.difference(_lastInterstitial ?? _startedAt) < gap) {
      return false;
    }
    _interstitialReady = false;
    try {
      final bool shown = await driver.showInterstitial();
      if (shown) {
        _lastInterstitial = clock.now();
      }
      return shown;
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Interstitial failed to show', error: e);
      return false;
    }
  }

  @override
  Future<void> loadRewarded() async {
    if (!canRequestAds()) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      _rewardedReady = await driver.loadRewarded(unitIds.rewarded);
    } on Object catch (e) {
      _rewardedReady = false;
      log?.log(LogLevel.warning, 'Rewarded ad failed to load', error: e);
    }
  }

  @override
  Future<bool> showRewarded() async {
    if (!_rewardedReady || !canRequestAds()) {
      return false;
    }
    _rewardedReady = false;
    try {
      return await driver.showRewarded();
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Rewarded ad failed to show', error: e);
      return false;
    }
  }
}
