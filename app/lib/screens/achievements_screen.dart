import 'package:flutter/widgets.dart';

import '../core/logic/achievements_engine.dart';
import '../core/models/achievement_def.dart';
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

/// Local milestones. Each shows its icon, its name, what it asks and whether
/// it is unlocked; nothing here is tied to faith or worth.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.achievementsTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.progress,
        builder: (BuildContext context, Widget? _) {
          final Set<String> done = app.progress.value.progress.achievements.toSet();
          final int count = AchievementCatalog.all.where((AchievementDef a) => done.contains(a.id)).length;
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              Text(l.achievementsProgress(count, AchievementCatalog.all.length), style: theme.text.title2),
              const SizedBox(height: Sp.md),
              for (final AchievementDef a in AchievementCatalog.all) ...<Widget>[
                _AchievementCard(l: l, def: a, unlocked: done.contains(a.id)),
                const SizedBox(height: Sp.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.l, required this.def, required this.unlocked});

  final AppLocalizations l;
  final AchievementDef def;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final String name = l.achievementName(def.id);
    final String detail = l.achievementDescription(def.id);
    final String state = unlocked ? l.achievementUnlocked : l.achievementLocked;
    return AppCard(
      semanticLabel: '$name. $state. $detail',
      child: Row(
        children: <Widget>[
          AppIcon(unlocked ? AppIcons.achievement : AppIcons.locked, color: unlocked ? theme.palette.accent : theme.palette.textTertiary),
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
          const SizedBox(width: Sp.sm),
          Text(state, style: theme.text.caption.copyWith(color: theme.palette.textSecondary)),
        ],
      ),
    );
  }
}
