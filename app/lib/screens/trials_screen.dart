import 'package:flutter/widgets.dart';

import '../core/catalog/struggle_catalog.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/struggle_def.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import 'parts/app_ad_slot.dart';
import 'parts/struggle_rows.dart';

/// The ten extra struggles as a second track. They open after tier 1 of the
/// Journey, one after another.
class TrialsScreen extends StatelessWidget {
  const TrialsScreen({super.key, required this.onOpen, required this.onBack});

  final ValueChanged<String> onOpen;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.trialsTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.progress,
        builder: (BuildContext context, Widget? _) {
          final Unlocks unlocks = ProgressionRules.unlocksFor(app.progress.value.progress);
          if (!unlocks.trialsOpen) {
            return EmptyState(icon: AppIcons.locked, title: l.trialsLocked);
          }
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: struggleRows(
              l: l,
              ids: <String>[for (final StruggleDef s in StruggleCatalog.trials) s.id],
              openIds: unlocks.trialIdsOpen.toSet(),
              progress: app.progress.value.progress,
              onOpen: onOpen,
            ),
          );
        },
      ),
    );
  }
}
