import 'package:flutter/widgets.dart';

import '../core/logic/progression_rules.dart';
import '../core/models/fight_config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import 'parts/app_ad_slot.dart';

/// Every way to play, with what is locked and how it opens. Choosing a mode
/// calls [onChoose]; the caller decides where each one goes.
class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key, required this.onChoose, required this.onBack});

  final ValueChanged<FightMode> onChoose;
  final VoidCallback onBack;

  static const List<FightMode> order = <FightMode>[
    FightMode.journey,
    FightMode.trials,
    FightMode.sparring,
    FightMode.daily,
    FightMode.endurance,
    FightMode.training,
  ];

  static IconData iconFor(FightMode mode) {
    switch (mode) {
      case FightMode.journey:
        return AppIcons.journey;
      case FightMode.trials:
        return AppIcons.trials;
      case FightMode.sparring:
        return AppIcons.fight;
      case FightMode.daily:
        return AppIcons.daily;
      case FightMode.endurance:
        return AppIcons.endurance;
      case FightMode.training:
        return AppIcons.training;
    }
  }

  /// Whether [mode] can be opened with the saved progress.
  static bool isOpen(Unlocks u, FightMode mode) {
    switch (mode) {
      case FightMode.trials:
        return u.trialsOpen;
      case FightMode.sparring:
        return u.sparringOpen;
      case FightMode.endurance:
        return u.enduranceOpen;
      case FightMode.journey:
      case FightMode.daily:
      case FightMode.training:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.modesTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.progress,
        builder: (BuildContext context, Widget? _) {
          final Unlocks unlocks = ProgressionRules.unlocksFor(app.progress.value.progress);
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              for (final FightMode mode in order) ...<Widget>[
                _ModeCard(l: l, mode: mode, open: isOpen(unlocks, mode), onChoose: onChoose),
                const SizedBox(height: Sp.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.l, required this.mode, required this.open, required this.onChoose});

  final AppLocalizations l;
  final FightMode mode;
  final bool open;
  final ValueChanged<FightMode> onChoose;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final String name = l.modeName(mode);
    final String detail = open ? l.modeDescription(mode) : l.modeUnlockHint(mode);
    return AppCard(
      semanticLabel: open ? '$name. $detail' : '$name. ${l.stateLocked}. $detail',
      onPressed: open ? () => onChoose(mode) : null,
      child: Row(
        children: <Widget>[
          AppIcon(open ? ModesScreen.iconFor(mode) : AppIcons.locked, color: theme.palette.accent),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: theme.text.callout),
                const SizedBox(height: Sp.xxs),
                Text(detail, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
              ],
            ),
          ),
          if (open) ...<Widget>[
            const SizedBox(width: Sp.sm),
            AppIcon(rtl ? AppIcons.back : AppIcons.forward, size: IconSizes.medium, color: theme.palette.textTertiary),
          ],
        ],
      ),
    );
  }
}
