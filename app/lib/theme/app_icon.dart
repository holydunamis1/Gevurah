import 'package:flutter/widgets.dart';

import 'app_theme.dart';
import 'tokens.dart';

/// The one icon widget. It fixes the default size and colour; the stroke
/// weight is fixed by `AppIcons`, which only uses the weight 400 font (a 2.0
/// stroke, so the mass matches 17 pt text). Take symbols from `AppIcons` only.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.symbol, {
    super.key,
    this.size = IconSizes.large,
    this.color,
    this.semanticLabel,
  });

  /// An alias from `AppIcons`.
  final IconData symbol;
  final double size;

  /// Defaults to the theme's primary text colour.
  final Color? color;

  /// Read by screen readers. Leave null for purely decorative icons.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      symbol,
      size: size,
      color: color ?? AppTheme.of(context).palette.textPrimary,
      semanticLabel: semanticLabel,
    );
  }
}
