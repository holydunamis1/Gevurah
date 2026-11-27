import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/models/settings_model.dart';
import '../l10n/app_localizations.dart';
import '../l10n/language_names.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';

/// First run: a one-line promise, a choice of language, and Play. Choosing a
/// language takes effect at once. There is no ad here. Consent is asked at
/// launch, before this screen, wherever the law requires it.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  Future<void> _play(AppProviders app) async {
    await app.settings.update((SettingsModel s) => s.copyWith(onboardingDone: true));
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: const SizedBox.shrink(),
      child: ListenableBuilder(
        listenable: app.locale,
        builder: (BuildContext context, Widget? _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Sp.lg),
                  children: <Widget>[
                    Text(l.onboardingPromise, style: theme.text.title1),
                    const SizedBox(height: Sp.lg),
                    SectionHeader(l.onboardingLanguage),
                    for (final String code in LocaleProvider.supported)
                      AppRow(
                        label: languageNames[code] ?? code,
                        leadingIcon: code == app.locale.value ? AppIcons.check : null,
                        showChevron: false,
                        onPressed: () => unawaited(app.locale.choose(code)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.lg),
                child: PrimaryButton(label: l.onboardingPlay, icon: AppIcons.play, onPressed: () => unawaited(_play(app))),
              ),
            ],
          );
        },
      ),
    );
  }
}
