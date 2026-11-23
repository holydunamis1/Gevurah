import 'package:flutter/widgets.dart';

import '../core/models/loadout.dart';
import '../core/models/stance.dart';
import '../core/models/verse_card_def.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/loadout_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/card_slot.dart';
import '../widgets/empty_state.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/segmented_control.dart';
import 'parts/app_ad_slot.dart';

/// Choose up to three earned verse cards and a stance.
class CardPickerScreen extends StatelessWidget {
  const CardPickerScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.cardsTitle, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.loadout,
        builder: (BuildContext context, Widget? _) {
          final LoadoutState state = app.loadout.value;
          final Loadout loadout = state.loadout;
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              Text(l.cardsHint, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              SectionHeader(l.cardsStance),
              SegmentedControl<Stance>(
                options: <SegmentOption<Stance>>[for (final Stance s in Stance.values) SegmentOption<Stance>(value: s, label: l.stanceName(s))],
                selected: loadout.stance,
                onChanged: (Stance s) => app.loadout.setStance(s),
              ),
              const SizedBox(height: Sp.xs),
              Text(l.stanceHint(loadout.stance), style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
              const SizedBox(height: Sp.md),
              if (!state.hasRoom) ...<Widget>[
                Text(l.cardsFull, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
                const SizedBox(height: Sp.sm),
              ],
              if (state.earned.isEmpty) EmptyState(icon: AppIcons.verse, title: l.cardsEmpty),
              for (final VerseCardDef c in state.earned) ...<Widget>[
                CardSlot(
                  type: c.type,
                  title: l.cardTypeName(c.type),
                  reference: l.reference(c.ref),
                  effect: l.cardEffect(c.type),
                  tradeoff: l.cardTradeoff(c.type),
                  equipped: state.isEquipped(c.id),
                  stateLabel: state.isEquipped(c.id) ? l.cardsEquipped : null,
                  onPressed: state.isEquipped(c.id) || state.hasRoom ? () => app.loadout.toggle(c.id) : null,
                ),
                const SizedBox(height: Sp.md),
              ],
            ],
          );
        },
      ),
    );
  }
}
