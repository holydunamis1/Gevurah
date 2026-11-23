import 'package:flutter/widgets.dart';

import '../../core/models/fight_state.dart';
import '../../core/models/move_def.dart';
import '../../core/models/player_state.dart';
import '../../providers/fight_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/icon_aliases.dart';
import '../../theme/tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/fight_meter.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/pressable.dart';
import '../../widgets/tell_overlay.dart';
import '../fight_controller.dart';

/// Every word the HUD shows, in the player's language. Supplied by the screen.
class FightHudLabels {
  const FightHudLabels({
    required this.resolve,
    required this.stamina,
    required this.weight,
    required this.breath,
    required this.pause,
    required this.roundLabel,
    required this.moveName,
  });

  final String resolve;
  final String stamina;
  final String weight;
  final String breath;
  final String pause;

  /// For example "Round 2 of 3".
  final String Function(int round) roundLabel;
  final String Function(MoveKind kind) moveName;
}

/// The overlay HUD: three meters, the round, a Breath button, a pause button and
/// the tell. Plain Flutter widgets, so every script and direction renders right.
/// It never shows a verse: scripture appears only in pauses.
class FightHud extends StatelessWidget {
  const FightHud({super.key, required this.controller, required this.labels, required this.locale, required this.onPause});

  final FightController controller;
  final FightHudLabels labels;

  /// The language code, for number formatting.
  final String locale;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return ListenableBuilder(
      listenable: controller.fight,
      builder: (BuildContext context, Widget? _) {
        final FightView? v = controller.fight.value;
        if (v == null) {
          return const SizedBox.shrink();
        }
        final FightState s = v.state;
        final PlayerState p = s.player;
        final Widget weight = FightMeter(kind: MeterKind.weight, value: s.weight, max: s.startingWeight <= 0 ? 1 : s.startingWeight, label: labels.weight, valueText: formatNumber(s.weight, locale));
        final Widget resolve = FightMeter(kind: MeterKind.resolve, value: p.resolve, max: PlayerState.maxResolve, label: labels.resolve, valueText: formatNumber(p.resolve, locale));
        final Widget stamina = FightMeter(kind: MeterKind.stamina, value: p.stamina, max: PlayerState.maxStamina, label: labels.stamina, valueText: formatNumber(p.stamina, locale));
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final bool wide = box.maxWidth > box.maxHeight;
            return Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: weight),
                        const SizedBox(width: Sp.md),
                        Expanded(child: resolve),
                        const SizedBox(width: Sp.md),
                        Expanded(child: stamina),
                      ],
                    )
                  else ...<Widget>[
                    weight,
                    const SizedBox(height: Sp.sm),
                    resolve,
                    const SizedBox(height: Sp.sm),
                    stamina,
                  ],
                  const SizedBox(height: Sp.sm),
              Row(
                children: <Widget>[
                  Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: AppChip(label: labels.roundLabel(s.round)))),
                  const SizedBox(width: Sp.sm),
                  _BreathButton(label: labels.breath, charges: p.breathCharges, locale: locale, onPressed: p.breathCharges > 0 ? controller.breathe : null, color: theme.palette.textPrimary),
                  const SizedBox(width: Sp.sm),
                  IconChip(icon: AppIcons.pause, semanticLabel: labels.pause, onPressed: onPause),
                ],
              ),
              Expanded(
                child: Center(
                  child: ValueListenableBuilder<ControllerPhase>(
                    valueListenable: controller.phaseNotifier,
                    builder: (BuildContext context, ControllerPhase phase, Widget? _) {
                      final MoveDef? move = v.move;
                      if (phase != ControllerPhase.waitingResponse || move == null) {
                        return const SizedBox.shrink();
                      }
                      return ValueListenableBuilder<double>(
                        valueListenable: controller.progressNotifier,
                        builder: (BuildContext context, double progress, Widget? _) =>
                            TellOverlay(kind: move.kind, progress: progress, label: labels.moveName(move.kind)),
                      );
                    },
                  ),
                ),
              ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BreathButton extends StatelessWidget {
  const _BreathButton({required this.label, required this.charges, required this.locale, required this.onPressed, required this.color});

  final String label;
  final int charges;
  final String locale;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: '$label ${formatNumber(charges, locale)}',
      excludeChildSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.sm + Sp.xs, vertical: Sp.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(AppIcons.breath, size: IconSizes.medium, color: color),
              const SizedBox(width: Sp.xs),
              Text(label, style: theme.text.footnote),
              const SizedBox(width: Sp.xs),
              Text(formatNumber(charges, locale), style: theme.text.footnote.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
