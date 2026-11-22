import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// A 40 by 40 chip around an icon, inside a 48 by 48 touch target. The label is
/// required: an icon-only control must always have a name for screen readers.
class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.icon, required this.semanticLabel, required this.onPressed});

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      child: Center(
        child: SizedBox(
          width: IconSizes.chip,
          height: IconSizes.chip,
          child: DecoratedBox(
            decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
            child: Center(child: AppIcon(icon, size: IconSizes.medium)),
          ),
        ),
      ),
    );
  }
}
