import 'package:flutter/widgets.dart';

import '../core/catalog/struggle_catalog.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/fight_config.dart';
import '../core/models/progress.dart';
import '../core/models/struggle_def.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/segmented_control.dart';
import 'parts/app_ad_slot.dart';

/// One introduction for the modes that need a choice before the opponent card:
/// Sparring (a struggle already met, and a difficulty), Training (any struggle)
/// and Endurance (no struggle). [onChoose] gets the struggle, or null for
/// Endurance, and the difficulty.
class ModeIntroScreen extends StatefulWidget {
  const ModeIntroScreen({super.key, required this.mode, required this.onChoose, required this.onBack})
      : assert(mode == FightMode.sparring || mode == FightMode.training || mode == FightMode.endurance);

  final FightMode mode;
  final void Function(String? struggleId, Difficulty difficulty) onChoose;
  final VoidCallback onBack;

  @override
  State<ModeIntroScreen> createState() => _ModeIntroScreenState();
}

class _ModeIntroScreenState extends State<ModeIntroScreen> {
  Difficulty _difficulty = Difficulty.standard;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    final FightMode mode = widget.mode;
    return ScreenFrame(
      navBar: NavBar(title: l.modeName(mode), onBack: widget.onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.progress,
        builder: (BuildContext context, Widget? _) {
          final Progress progress = app.progress.value.progress;
          final List<Widget> body = <Widget>[
            Text(l.modeDescription(mode), style: theme.text.body),
            const SizedBox(height: Sp.lg),
          ];
          if (mode == FightMode.endurance) {
            body.add(
              PrimaryButton(
                label: l.modeStart,
                icon: AppIcons.play,
                onPressed: ProgressionRules.canFight(progress, mode, '') ? () => widget.onChoose(null, Difficulty.standard) : null,
              ),
            );
          } else {
            if (mode == FightMode.sparring) {
              body
                ..add(SectionHeader(l.difficultyTitle))
                ..add(
                  SegmentedControl<Difficulty>(
                    options: <SegmentOption<Difficulty>>[
                      for (final Difficulty d in Difficulty.values) SegmentOption<Difficulty>(value: d, label: l.difficultyName(d)),
                    ],
                    selected: _difficulty,
                    onChanged: (Difficulty d) => setState(() => _difficulty = d),
                  ),
                )
                ..add(const SizedBox(height: Sp.xs))
                ..add(Text(l.difficultyHint, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)))
                ..add(const SizedBox(height: Sp.lg));
            }
            body.add(SectionHeader(l.modeIntroChoose));
            final List<StruggleDef> choices = <StruggleDef>[
              for (final StruggleDef s in StruggleCatalog.all)
                if (ProgressionRules.canFight(progress, mode, s.id)) s,
            ];
            if (choices.isEmpty) {
              body.add(Text(l.modeEmptySparring, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)));
            }
            for (final StruggleDef s in choices) {
              body
                ..add(
                  AppCard(
                    leadingIcon: AppIcons.fight,
                    label: l.struggleName(s.id),
                    showChevron: true,
                    onPressed: () => widget.onChoose(s.id, mode == FightMode.sparring ? _difficulty : Difficulty.standard),
                  ),
                )
                ..add(const SizedBox(height: Sp.md));
            }
          }
          return ListView(padding: const EdgeInsets.all(Sp.lg), children: body);
        },
      ),
    );
  }
}
