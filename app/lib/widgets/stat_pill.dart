import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A label and a value side by side, for results and the HUD.
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      label: label,
      value: value,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.sm + Sp.xs, vertical: Sp.xs + Sp.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(child: Text(label, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
              const SizedBox(width: Sp.sm),
              Flexible(child: Text(value, style: theme.text.footnote.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ),
    );
  }
}
