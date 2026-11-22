import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// The one primary action: filled accent, at least 48 high (it grows with
/// large text), radius 12, 40 percent opacity when disabled.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = true});

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Fill the available width (the default) or fit the label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          AppIcon(icon!, size: IconSizes.medium, color: theme.palette.onAccent),
          const SizedBox(width: Sp.sm),
        ],
        Flexible(
          child: Text(label, textAlign: TextAlign.center, style: theme.text.callout.copyWith(color: theme.palette.onAccent)),
        ),
      ],
    );
    return Pressable(
      onPressed: onPressed,
      minHeight: IconSizes.target,
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.palette.accent, borderRadius: BorderRadius.circular(Radii.button)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm + Sp.xs),
          child: content,
        ),
      ),
    );
  }
}
