import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';

/// A small "Ads removed" badge. Shows nothing when [adsRemoved] is false.
class EntitlementBadge extends StatelessWidget {
  const EntitlementBadge({super.key, required this.adsRemoved, required this.label});

  final bool adsRemoved;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!adsRemoved) {
      return const SizedBox.shrink();
    }
    final AppTheme theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.sm + Sp.xs, vertical: Sp.xs + Sp.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(AppIcons.check, size: IconSizes.small, color: theme.palette.success),
            const SizedBox(width: Sp.xs),
            Flexible(child: Text(label, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
          ],
        ),
      ),
    );
  }
}
