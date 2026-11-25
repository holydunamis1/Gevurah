import 'package:flutter/foundation.dart';

import '../core/logic/daily_seed.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/settings_model.dart';
import '../core/ports/clock_port.dart';
import 'ad_provider.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

/// How a rewarded-ad request ended.
enum RewardResult {
  /// The player watched the ad and earned the reward.
  earned,

  /// The ad was closed early or failed; nothing is granted.
  notEarned,

  /// No ad is ready, ads are off, or consent is missing.
  unavailable,
}

/// The rewarded-ad offers. Every offer is the player's choice; none is needed
/// for any unlock, and they stay available after Remove Ads. The ad itself is
/// shown by [AdProvider], which checks consent and the remote flag.
class RewardsProvider extends ChangeNotifier {
  RewardsProvider({required AdProvider adProvider, required ProgressProvider progressProvider, required SettingsProvider settingsProvider, required ClockPort clockPort})
      : _ads = adProvider,
        _progress = progressProvider,
        _settings = settingsProvider,
        _clock = clockPort;

  final AdProvider _ads;
  final ProgressProvider _progress;
  final SettingsProvider _settings;
  final ClockPort _clock;

  bool _busy = false;

  /// True when an offer may be shown: ads are allowed and one is loaded.
  bool get offered => _ads.rewardedReady;

  /// True when an offer may be shown and no ad is already playing.
  bool get available => offered && !_busy;

  /// Shows one rewarded ad. The reward is granted by the caller only on
  /// [RewardResult.earned].
  Future<RewardResult> watch() async {
    if (_busy || !_ads.rewardedReady) {
      return RewardResult.unavailable;
    }
    _busy = true;
    try {
      return await _ads.watchRewarded() ? RewardResult.earned : RewardResult.notEarned;
    } finally {
      _busy = false;
    }
  }

  String get _today => DailySeed.dateKey(_clock.now());

  /// The missed Daily day an ad could restore today, or null: only when exactly
  /// one day broke the streak and no restore happened in the last seven days.
  String? get restorableDay {
    final String? day = ProgressionRules.restorableDay(_progress.progress, _today);
    if (day == null || !ProgressionRules.restoreAllowed(_settings.settings.dailyRestoredOn, _today)) {
      return null;
    }
    return day;
  }

  /// Watches an ad and, if it is earned, restores the missed Daily day.
  Future<RewardResult> restoreDailyDay() async {
    final String? day = restorableDay;
    if (day == null) {
      return RewardResult.unavailable;
    }
    final RewardResult result = await watch();
    if (result == RewardResult.earned) {
      await _progress.restoreDailyDay(day);
      final String today = _today;
      await _settings.update((SettingsModel s) => s.copyWith(dailyRestoredOn: today));
    }
    return result;
  }
}
