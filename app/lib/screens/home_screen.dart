import 'package:flutter/widgets.dart';

import '../core/logic/progression_rules.dart';
import '../core/models/progress.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/daily_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_chip.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/warning_banner.dart';
import 'parts/app_ad_slot.dart';

/// The first screen: continue the journey, today's bout, and the other places.
/// Navigation is supplied by the caller.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onContinue,
    required this.onJourney,
    required this.onDaily,
    required this.onModes,
    required this.onCards,
    required this.onLibrary,
    required this.onSettings,
  });

  /// Called with the id of the struggle to fight next.
  final ValueChanged<String> onContinue;
  final VoidCallback onJourney;
  final VoidCallback onDaily;
  final VoidCallback onModes;
  final VoidCallback onCards;
  final VoidCallback onLibrary;
  final VoidCallback onSettings;

  /// The next career struggle: the first open one not yet won, else the last open.
  static String? nextStruggle(Progress p) {
    final List<String> open = ProgressionRules.unlocksFor(p).careerOpen;
    for (final String id in open) {
      if ((p.bouts[id]?.wins ?? 0) == 0) {
        return id;
      }
    }
    return open.isEmpty ? null : open.last;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ScreenFrame(
      navBar: NavBar(
        title: l.appName,
        actions: <Widget>[IconChip(icon: AppIcons.settings, semanticLabel: l.homeSettings, onPressed: onSettings)],
      ),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[app.progress, app.daily]),
        builder: (BuildContext context, Widget? _) {
          final ProgressState ps = app.progress.value;
          final DailyState daily = app.daily.value;
          final String? next = nextStruggle(ps.progress);
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              ..._warnings(l, app, ps),
              if (next != null) ...<Widget>[
                PrimaryButton(label: l.homeContinue, icon: AppIcons.play, onPressed: () => onContinue(next)),
                const SizedBox(height: Sp.sm),
                Text(l.homeNext(l.struggleName(next)), style: AppTheme.of(context).text.callout.copyWith(color: AppTheme.of(context).palette.textSecondary)),
                const SizedBox(height: Sp.lg),
              ],
              AppCard(leadingIcon: AppIcons.journey, label: l.homeJourney, showChevron: true, onPressed: onJourney),
              const SizedBox(height: Sp.md),
              if (daily.enabled) ...<Widget>[
                AppCard(
                  leadingIcon: AppIcons.daily,
                  label: l.homeDaily,
                  value: daily.doneToday ? l.homeDailyDone : (daily.streak > 0 ? l.homeDailyStreak(daily.streak) : null),
                  showChevron: true,
                  onPressed: onDaily,
                ),
                const SizedBox(height: Sp.md),
              ],
              AppCard(leadingIcon: AppIcons.fight, label: l.homeModes, showChevron: true, onPressed: onModes),
              const SizedBox(height: Sp.md),
              AppCard(leadingIcon: AppIcons.guard, label: l.homeCards, showChevron: true, onPressed: onCards),
              const SizedBox(height: Sp.md),
              AppCard(leadingIcon: AppIcons.library, label: l.homeLibrary, showChevron: true, onPressed: onLibrary),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _warnings(AppLocalizations l, AppProviders app, ProgressState ps) {
    final List<Widget> out = <Widget>[];
    if (ps.status == ProgressStatus.readOnly) {
      out.add(WarningBanner(message: l.homeReadOnly));
    }
    if (ps.saveFailed) {
      out.add(WarningBanner(message: l.homeSaveFailed, actionLabel: l.homeSaveRetry, onAction: app.progress.retrySave));
    }
    if (ps.notice != ProgressNotice.none) {
      out.add(WarningBanner(
        message: ps.notice == ProgressNotice.recoveredFromBackup ? l.homeNoticeRecovered : l.homeNoticeStartedClean,
        actionLabel: l.homeNoticeDismiss,
        onAction: app.progress.dismissNotice,
      ));
    }
    return <Widget>[for (final Widget w in out) ...<Widget>[w, const SizedBox(height: Sp.md)]];
  }
}
