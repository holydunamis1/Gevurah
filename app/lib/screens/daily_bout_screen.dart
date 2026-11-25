import 'package:flutter/widgets.dart';

import '../core/models/curated_verse.dart';
import '../core/models/daily_challenge.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/daily_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/star_row.dart';
import 'parts/app_ad_slot.dart';
import 'parts/reminder_controls.dart';
import 'parts/reward_offer.dart';
import 'parts/verse_block.dart';

/// Today's seeded bout, the same for everyone, with the streak, the daily verse
/// and the opt-in reminder. Starting hands the challenge to the caller, which
/// opens the opponent card.
class DailyBoutScreen extends StatelessWidget {
  const DailyBoutScreen({super.key, required this.onStart, required this.onBack});

  final ValueChanged<DailyChallenge> onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.homeDaily, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.daily,
        builder: (BuildContext context, Widget? _) {
          final DailyState daily = app.daily.value;
          if (!daily.enabled) {
            return EmptyState(icon: AppIcons.daily, title: l.dailyOff);
          }
          final String id = daily.challenge.struggleId;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Sp.lg),
                  children: <Widget>[
                    Text(l.dailyToday, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
                    const SizedBox(height: Sp.xs),
                    Text(l.struggleName(id), style: theme.text.headline),
                    const SizedBox(height: Sp.sm),
                    Text(l.struggleTell(id), style: theme.text.body),
                    if (daily.streak > 0) ...<Widget>[
                      const SizedBox(height: Sp.md),
                      Text(l.homeDailyStreak(daily.streak), style: theme.text.title2),
                    ],
                    if (daily.doneToday) ...<Widget>[
                      const SizedBox(height: Sp.md),
                      StarRow(stars: daily.stars, label: l.resultStars(daily.stars)),
                      const SizedBox(height: Sp.xs),
                      Text(l.dailyDone, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
                    ],
                    const SizedBox(height: Sp.lg),
                    VerseBlock(load: (verses) => verses.forMoment(VerseMoment.daily, seed: daily.challenge.seed)),
                    RewardOffer(
                      label: l.rewardRestore,
                      icon: AppIcons.daily,
                      run: app.rewards.restoreDailyDay,
                      enabled: app.rewards.restorableDay != null,
                      doneLabel: l.rewardRestored,
                    ),
                    SectionHeader(l.homeDaily),
                    const ReminderControls(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.lg),
                child: PrimaryButton(label: l.opponentStart, icon: AppIcons.fight, onPressed: daily.doneToday ? null : () => onStart(daily.challenge)),
              ),
            ],
          );
        },
      ),
    );
  }
}
