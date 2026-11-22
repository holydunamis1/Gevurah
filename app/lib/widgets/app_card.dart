import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// The one card: a filled surface with a hairline border and radius 16. Give
/// it a [label] (and optionally an icon, a value and a chevron), or a custom
/// [child]. A tappable card dims to 0.7 while pressed.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.leadingIcon,
    this.label,
    this.value,
    this.child,
    this.onPressed,
    this.showChevron = false,
    this.semanticLabel,
  }) : assert(label != null || child != null, 'A card needs a label or a child');

  final IconData? leadingIcon;
  final String? label;
  final String? value;

  /// Custom content in place of the label row.
  final Widget? child;
  final VoidCallback? onPressed;
  final bool showChevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Widget content = child ??
        Row(
          children: <Widget>[
            if (leadingIcon != null) ...<Widget>[
              AppIcon(leadingIcon!, color: theme.palette.accent),
              const SizedBox(width: Sp.md),
            ],
            Expanded(child: Text(label!, style: theme.text.callout)),
            if (value != null) ...<Widget>[
              const SizedBox(width: Sp.sm),
              Flexible(child: Text(value!, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
            ],
            if (showChevron) ...<Widget>[
              const SizedBox(width: Sp.sm),
              AppIcon(rtl ? AppIcons.back : AppIcons.forward, size: IconSizes.medium, color: theme.palette.textTertiary),
            ],
          ],
        );
    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgSecondary,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: theme.palette.hairline, width: Strokes.hairline),
      ),
      child: Padding(padding: const EdgeInsets.all(Sp.md), child: content),
    );
    if (onPressed == null) {
      return box;
    }
    return Pressable(onPressed: onPressed, semanticLabel: semanticLabel, minHeight: 0, minWidth: 0, child: box);
  }
}
