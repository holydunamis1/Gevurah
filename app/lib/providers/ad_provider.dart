import 'package:flutter/foundation.dart';

import '../core/config/remote_flags.dart';
import '../core/ports/ads_port.dart';
import 'consent_provider.dart';
import 'entitlement_provider.dart';
import 'flags_provider.dart';

/// Decides what ad surface may appear. Rules: nothing before consent; nothing
/// when a remote flag is off; no banner or interstitial once ads are removed;
/// rewarded ads stay available (they are always the player's choice).
class AdProvider extends ValueNotifier<bool> {
  AdProvider({
    required this.ads,
    required ConsentProvider consent,
    required EntitlementProvider entitlement,
    required FlagsProvider flags,
  })  : _consent = consent,
        _entitlement = entitlement,
        _flags = flags,
        super(false) {
    consent.addListener(_recompute);
    entitlement.addListener(_recompute);
    flags.addListener(_recompute);
    _recompute();
  }

  final AdsPort ads;
  final ConsentProvider _consent;
  final EntitlementProvider _entitlement;
  final FlagsProvider _flags;

  /// The value is whether the banner may be shown.
  bool get bannerVisible => value;

  RemoteFlags get _f => _flags.value;

  bool get _adsAllowed => _consent.canRequestAds && _f.adsEnabled;

  bool get interstitialAllowed => _adsAllowed && _f.interstitialsEnabled && !_entitlement.adsRemoved;

  bool get rewardedAllowed => _adsAllowed && _f.rewardedEnabled;

  void _recompute() {
    value = _adsAllowed && !_entitlement.adsRemoved;
  }

  /// Starts the SDK (when consent allows) and loads the first ads.
  Future<void> start() async {
    if (!_adsAllowed) {
      return;
    }
    try {
      await ads.initialize();
      if (interstitialAllowed) {
        await ads.loadInterstitial();
      }
      if (rewardedAllowed) {
        await ads.loadRewarded();
      }
    } on Object {
      // No ad is not an error.
    }
  }

  /// Offered only at a natural pause after a bout. Returns whether one was shown.
  Future<bool> maybeShowInterstitial() async {
    if (!interstitialAllowed || !ads.interstitialReady) {
      return false;
    }
    try {
      final bool shown = await ads.showInterstitial();
      await ads.loadInterstitial();
      return shown;
    } on Object {
      return false;
    }
  }

  bool get rewardedReady => rewardedAllowed && ads.rewardedReady;

  /// Shows a rewarded ad the player chose to watch. True only if the reward was earned.
  Future<bool> watchRewarded() async {
    if (!rewardedReady) {
      return false;
    }
    try {
      final bool earned = await ads.showRewarded();
      await ads.loadRewarded();
      return earned;
    } on Object {
      return false;
    }
  }

  @override
  void dispose() {
    _consent.removeListener(_recompute);
    _entitlement.removeListener(_recompute);
    _flags.removeListener(_recompute);
    super.dispose();
  }
}
