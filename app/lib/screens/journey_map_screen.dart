import 'package:flutter/widgets.dart';

import '../core/catalog/struggle_catalog.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/struggle_def.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../theme/tokens.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import 'parts/app_ad_slot.dart';
import 'parts/struggle_rows.dart';

/// The career: four tiers of struggles with stars. A struggle opens when the
/// one before it is overcome.
class JourneyMapScreen extends StatelessWidget {
  const JourneyMapScreen({super.key, required this.onOpen, required this.onBack});

  /// Called with the id of the open struggle the player chose.
  final ValueChanged<String> onOpen;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.journeyTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.progress,
        builder: (BuildContext context, Widget? _) {
          final Unlocks unlocks = ProgressionRules.unlocksFor(app.progress.value.progress);
          final Set<String> open = unlocks.careerOpen.toSet();
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              for (int tier = 1; tier <= 4; tier++) ...<Widget>[
                SectionHeader(
                  unlocks.tiersCleared.contains(tier) ? '${l.tierLabel(tier)} · ${l.tierCleared}' : l.tierLabel(tier),
                ),
                ...struggleRows(
                  l: l,
                  ids: <String>[for (final StruggleDef s in StruggleCatalog.careerTier(tier)) s.id],
                  openIds: open,
                  progress: app.progress.value.progress,
                  onOpen: onOpen,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
