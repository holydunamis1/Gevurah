import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/models/settings_model.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../l10n/language_names.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/entitlement_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_row.dart';
import '../widgets/bottom_sheet.dart';
import '../widgets/entitlement_badge.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/segmented_control.dart';
import '../widgets/toggle_row.dart';
import 'parts/app_ad_slot.dart';
import 'parts/purchase_feedback.dart';
import 'parts/reminder_controls.dart';

/// Every setting in one place: language, appearance, play options, the daily
/// reminder, ads and purchases (Restore is always visible), and the legal and
/// support links. Links open through callbacks because they need a platform
/// plugin the shell owns.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onAchievements,
    required this.onUpgrade,
    required this.onSupport,
    required this.onPrivacyPolicy,
    required this.onLicenses,
    required this.onHowToPlay,
  });

  final VoidCallback onBack;
  final VoidCallback onAchievements;
  final VoidCallback onUpgrade;
  final VoidCallback onSupport;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onLicenses;
  final VoidCallback onHowToPlay;

  Future<void> _pickLanguage(BuildContext context, AppLocalizations l, AppProviders app) async {
    await showAppBottomSheet<void>(
      context,
      barrierLabel: l.commonClose,
      builder: (BuildContext sheet) => AppBottomSheet(
        title: l.settingsLanguage,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: app.settings,
            builder: (BuildContext context, Widget? _) {
              final String? chosen = app.settings.settings.localeCode;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppRow(
                    label: l.settingsLanguagePhone,
                    leadingIcon: chosen == null ? AppIcons.check : null,
                    showChevron: false,
                    onPressed: () {
                      unawaited(app.locale.choose(null));
                      Navigator.of(sheet).pop();
                    },
                  ),
                  for (final String code in LocaleProvider.supported)
                    AppRow(
                      label: languageNames[code] ?? code,
                      leadingIcon: chosen == code ? AppIcons.check : null,
                      showChevron: false,
                      onPressed: () {
                        unawaited(app.locale.choose(code));
                        Navigator.of(sheet).pop();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.settingsTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[app.settings, app.entitlement, app.consent, app.locale]),
        builder: (BuildContext context, Widget? _) {
          final SettingsModel s = app.settings.settings;
          final bool removed = app.entitlement.value.adsRemoved;
          final bool busy = app.entitlement.value.activity != EntitlementActivity.idle;
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              AppRow(label: l.howToOpen, leadingIcon: AppIcons.help, onPressed: onHowToPlay),
              AppRow(label: l.settingsAchievements, leadingIcon: AppIcons.achievement, onPressed: onAchievements),
              SectionHeader(l.settingsLanguage),
              AppRow(
                label: l.settingsLanguage,
                leadingIcon: AppIcons.language,
                value: s.localeCode == null ? l.settingsLanguagePhone : (languageNames[s.localeCode] ?? s.localeCode),
                onPressed: () => unawaited(_pickLanguage(context, l, app)),
              ),
              SectionHeader(l.settingsTheme),
              SegmentedControl<ThemeChoice>(
                options: <SegmentOption<ThemeChoice>>[
                  for (final ThemeChoice c in ThemeChoice.values) SegmentOption<ThemeChoice>(value: c, label: l.themeName(c)),
                ],
                selected: s.themeChoice,
                onChanged: (ThemeChoice c) => unawaited(app.theme.choose(c)),
              ),
              SectionHeader(l.settingsPlay),
              ToggleRow(
                label: l.settingsSound,
                icon: AppIcons.sound,
                value: s.soundOn,
                onChanged: (bool v) => unawaited(app.settings.update((SettingsModel m) => m.copyWith(soundOn: v))),
              ),
              ToggleRow(
                label: l.settingsMusic,
                icon: AppIcons.sound,
                value: s.musicOn,
                onChanged: (bool v) => unawaited(app.settings.update((SettingsModel m) => m.copyWith(musicOn: v))),
              ),
              ToggleRow(
                label: l.settingsHaptics,
                icon: AppIcons.haptics,
                value: s.hapticsOn,
                onChanged: (bool v) => unawaited(app.settings.update((SettingsModel m) => m.copyWith(hapticsOn: v))),
              ),
              SectionHeader(l.settingsReminder),
              const ReminderControls(),
              SectionHeader(l.settingsStore),
              const PurchaseFeedback(),
              if (removed)
                EntitlementBadge(adsRemoved: true, label: l.settingsAdsRemoved)
              else
                AppRow(label: l.settingsRemoveAds, leadingIcon: AppIcons.removeAds, onPressed: onUpgrade),
              AppRow(
                label: l.settingsRestore,
                leadingIcon: AppIcons.retry,
                showChevron: false,
                onPressed: busy ? null : () => unawaited(app.entitlement.restore()),
              ),
              if (app.consent.privacyOptionsRequired)
                AppRow(
                  label: l.settingsPrivacyOptions,
                  leadingIcon: AppIcons.privacy,
                  onPressed: () => unawaited(app.consent.showPrivacyOptions()),
                ),
              SectionHeader(l.settingsAbout),
              AppRow(label: l.settingsSupport, leadingIcon: AppIcons.mail, onPressed: onSupport),
              AppRow(label: l.settingsPrivacy, leadingIcon: AppIcons.privacy, onPressed: onPrivacyPolicy),
              AppRow(label: l.settingsLicenses, leadingIcon: AppIcons.info, onPressed: onLicenses),
            ],
          );
        },
      ),
    );
  }
}
