import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A settings row with a switch. The state is shown by the knob position and
/// the filled track, and read aloud as on or off by screen readers.
class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.label, required this.value, required this.onChanged, this.icon, this.subtitle});

  final String label;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final String? subtitle;

  static const double trackWidth = 48;
  static const double trackHeight = 28;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final bool enabled = onChanged != null;
    final Duration duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150);
    final Widget track = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: trackWidth,
      height: trackHeight,
      padding: const EdgeInsets.all(Sp.xxs),
      decoration: BoxDecoration(
        color: value ? theme.palette.accent : theme.palette.bgTertiary,
        borderRadius: BorderRadius.circular(trackHeight / 2),
        border: Border.all(color: value ? theme.palette.accent : theme.palette.hairline, width: Strokes.hairline),
      ),
      alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(color: value ? theme.palette.onAccent : theme.palette.textSecondary, shape: BoxShape.circle),
        child: const SizedBox(width: trackHeight - 2 * Sp.xxs - 2, height: trackHeight - 2 * Sp.xxs - 2),
      ),
    );
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      onTap: enabled ? () => onChanged!(!value) : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: IconSizes.target),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.sm),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    AppIcon(icon!, color: theme.palette.textSecondary),
                    const SizedBox(width: Sp.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(label, style: theme.text.callout),
                        if (subtitle != null) Text(subtitle!, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  track,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
