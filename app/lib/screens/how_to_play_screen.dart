import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import 'parts/app_ad_slot.dart';

/// Four short cards: watch the tell, answer on the beat, strike when it opens,
/// and Breath and Stamina. Shown once after onboarding, and from Settings and
/// the first opponent card. Never blocks: Back leaves at any time.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    final List<(IconData, String, String)> cards = <(IconData, String, String)>[
      (AppIcons.target, l.howToWatchTitle, l.howToWatchBody),
      (AppIcons.guard, l.howToAnswerTitle, l.howToAnswerBody),
      (AppIcons.strike, l.howToStrikeTitle, l.howToStrikeBody),
      (AppIcons.breath, l.howToBreathTitle, l.howToBreathBody),
    ];
    return ScreenFrame(
      navBar: NavBar(title: l.howToTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Sp.lg),
              children: <Widget>[
                for (final (IconData icon, String title, String body) in cards) ...<Widget>[
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppIcon(icon, size: IconSizes.medium, color: theme.palette.accent),
                        const SizedBox(width: Sp.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(title, style: theme.text.title2),
                              const SizedBox(height: Sp.xxs),
                              Text(body, style: theme.text.body),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.lg),
            child: PrimaryButton(label: l.howToStart, icon: AppIcons.check, onPressed: onBack),
          ),
        ],
      ),
    );
  }
}
