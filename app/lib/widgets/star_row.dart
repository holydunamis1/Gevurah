import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';

/// Zero to three stars with a text label ("2 of 3"). Earned stars are drawn in
/// the accent colour and unearned ones faded, and the label carries the same
/// information in words. Stars measure skill only.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, required this.label, this.size = IconSizes.large}) : assert(stars >= 0 && stars <= 3);

  final int stars;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Sp.xs),
              child: Opacity(
                key: ValueKey<String>(i < stars ? 'star-on-$i' : 'star-off-$i'),
                opacity: i < stars ? 1 : 0.3,
                child: AppIcon(AppIcons.star, size: size, color: i < stars ? theme.palette.accent : theme.palette.textTertiary),
              ),
            ),
          const SizedBox(width: Sp.xs),
          Flexible(child: Text(label, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
        ],
      ),
    );
  }
}
