import 'package:flutter/widgets.dart';

import 'app_theme.dart';
import 'tokens.dart';

/// The one icon widget. It fixes the stroke weight (Lucide weight 400, a
/// 2.0 stroke, so the mass matches 17 pt text) and the default size, and
/// takes its symbol from [AppIcons] only.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.symbol, {
    super.key,
    this.size = IconSizes.large,
    this.color,
    this.semanticLabel,
  });

  /// An alias from `AppIcons`; any symbol's code point works with the fixed weight.
  final IconData symbol;
  final double size;

  /// Defaults to the theme's primary text colour.
  final Color? color;

  /// Read by screen readers. Leave null for purely decorative icons.
  final String? semanticLabel;

  static const String _fixedWeightFamily = 'Lucide400';
  static const String _package = 'lucide_icons_flutter';

  @override
  Widget build(BuildContext context) {
    final IconData glyph = IconData(
      symbol.codePoint,
      fontFamily: _fixedWeightFamily,
      fontPackage: _package,
      matchTextDirection: symbol.matchTextDirection,
    );
    return Icon(
      glyph,
      size: size,
      color: color ?? AppTheme.of(context).palette.textPrimary,
      semanticLabel: semanticLabel,
    );
  }
}
