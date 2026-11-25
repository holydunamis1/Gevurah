import 'package:flutter/widgets.dart';

import '../core/ports/audio_port.dart';
import '../core/ports/clock_port.dart';
import '../core/ports/haptics_port.dart';
import '../core/ports/notification_port.dart';
import '../core/ports/billing_port.dart';
import '../core/ports/ads_port.dart';
import '../core/ports/consent_port.dart';
import '../core/ports/storage_port.dart';
import '../core/config/remote_flags.dart';
import '../core/storage/progress_store.dart';
import '../core/catalog/card_catalog.dart';
import '../core/verses/verse_repository.dart';
import 'achievements_provider.dart';
import 'ad_provider.dart';
import 'consent_provider.dart';
import 'daily_provider.dart';
import 'rewards_provider.dart';
import 'entitlement_provider.dart';
import 'fight_provider.dart';
import 'flags_provider.dart';
import 'loadout_provider.dart';
import 'locale_provider.dart';
import 'progress_provider.dart';
import 'reminder_provider.dart';
import 'settings_provider.dart';
import 'theme_provider.dart';
import 'verse_provider.dart';

/// Every provider, built once from the ports, in dependency order.
class AppProviders {
  AppProviders._({
    required this.settings,
    required this.theme,
    required this.locale,
    required this.progress,
    required this.loadout,
    required this.entitlement,
    required this.consent,
    required this.flags,
    required this.ads,
    required this.rewards,
    required this.daily,
    required this.achievements,
    required this.fight,
    required this.verses,
    required this.reminder,
    this.haptics,
    this.audio,
    this.bannerBuilder,
  });

  factory AppProviders.create({
    required StoragePort storage,
    required ClockPort clock,
    required BillingPort billing,
    required ConsentPort consent,
    required AdsPort ads,
    required NotificationPort notifications,
    required VerseRepository verseRepository,
    required Future<RemoteFlags> Function() fetchFlags,
    List<String> deviceLanguages = const <String>[],
    HapticsPort? haptics,
    AudioPort? audio,
    WidgetBuilder? bannerBuilder,
  }) {
    final SettingsProvider settings = SettingsProvider(storage);
    final LocaleProvider locale = LocaleProvider(settings, deviceLanguages: deviceLanguages);
    final ProgressProvider progress = ProgressProvider(ProgressStore(storage, starterCardIds: CardCatalog.starterIds));
    final EntitlementProvider entitlement = EntitlementProvider(billing);
    final ConsentProvider consentProvider = ConsentProvider(consent);
    final FlagsProvider flags = FlagsProvider(fetchFlags);
    final AchievementsProvider achievements = AchievementsProvider(progress);
    final AdProvider adProvider = AdProvider(ads: ads, consent: consentProvider, entitlement: entitlement, flags: flags);
    return AppProviders._(
      settings: settings,
      theme: ThemeProvider(settings),
      locale: locale,
      progress: progress,
      loadout: LoadoutProvider(progress),
      entitlement: entitlement,
      consent: consentProvider,
      flags: flags,
      ads: adProvider,
      rewards: RewardsProvider(ads: adProvider, progress: progress, settings: settings, clock: clock),
      daily: DailyProvider(clock: clock, progress: progress, flags: flags),
      achievements: achievements,
      fight: FightProvider(progress: progress, achievements: achievements, clock: clock),
      verses: VerseProvider(verseRepository, locale),
      reminder: ReminderProvider(notifications: notifications, settings: settings),
      haptics: haptics,
      audio: audio,
      bannerBuilder: bannerBuilder,
    );
  }

  final SettingsProvider settings;
  final ThemeProvider theme;
  final LocaleProvider locale;
  final ProgressProvider progress;
  final LoadoutProvider loadout;
  final EntitlementProvider entitlement;
  final ConsentProvider consent;
  final FlagsProvider flags;
  final AdProvider ads;
  final RewardsProvider rewards;
  final DailyProvider daily;
  final AchievementsProvider achievements;
  final FightProvider fight;
  final VerseProvider verses;
  final ReminderProvider reminder;

  /// Device feedback for the fight; null when the platform has none.
  final HapticsPort? haptics;
  final AudioPort? audio;

  /// Builds the platform banner ad, or null when no banner exists.
  final WidgetBuilder? bannerBuilder;

  /// Launch order: what the first screen needs loads first; the rest never
  /// blocks it. Each step handles its own failure.
  Future<void> startUp() async {
    await settings.load();
    await progress.load();
    daily.refresh();
    // Consent first, then ads, so nothing is requested before consent.
    await Future.wait<void>(<Future<void>>[entitlement.start(), flags.refresh(), consent.refresh()]);
    await ads.start();
  }

  void dispose() {
    fight.dispose();
    reminder.dispose();
    verses.dispose();
    daily.dispose();
    rewards.dispose();
    ads.dispose();
    loadout.dispose();
    theme.dispose();
    locale.dispose();
    achievements.dispose();
    entitlement.dispose();
    consent.dispose();
    flags.dispose();
    progress.dispose();
    settings.dispose();
  }
}
