import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A small labelled pill for metadata, such as a tier or a mode.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.sm + Sp.xs, vertical: Sp.xs + Sp.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              AppIcon(icon!, size: IconSizes.small, color: theme.palette.textSecondary),
              const SizedBox(width: Sp.xs),
            ],
            Flexible(child: Text(label, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
          ],
        ),
      ),
    );
  }
}
