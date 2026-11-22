import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';

enum MeterKind { resolve, stamina, weight }

/// One fight bar. It always carries an icon, a text label and a number, so it
/// never relies on colour alone.
class FightMeter extends StatelessWidget {
  const FightMeter({
    super.key,
    required this.kind,
    required this.value,
    required this.max,
    required this.label,
    required this.valueText,
  }) : assert(max > 0, 'A meter needs a positive maximum');

  final MeterKind kind;
  final int value;
  final int max;

  /// The meter's name, for example "Resolve".
  final String label;

  /// The formatted number shown beside the bar.
  final String valueText;

  static IconData iconFor(MeterKind kind) {
    switch (kind) {
      case MeterKind.resolve:
        return AppIcons.resolve;
      case MeterKind.stamina:
        return AppIcons.stamina;
      case MeterKind.weight:
        return AppIcons.weight;
    }
  }

  Color _fill(AppPalette p) {
    switch (kind) {
      case MeterKind.resolve:
        return p.resolveFill;
      case MeterKind.stamina:
        return p.staminaFill;
      case MeterKind.weight:
        return p.weightFill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final double fraction = (value / max).clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: valueText,
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          AppIcon(iconFor(kind), size: IconSizes.medium, color: theme.palette.textSecondary),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(label, style: theme.text.caption.copyWith(color: theme.palette.textSecondary))),
                    Text(valueText, style: theme.text.caption.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: Sp.xxs),
                DecoratedBox(
                  decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
                  child: SizedBox(
                    height: Sp.sm,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        key: const ValueKey<String>('fill'),
                        widthFactor: fraction,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: _fill(theme.palette), borderRadius: BorderRadius.circular(Radii.chip)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
