import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

enum FeedbackKind { success, failure, info }

/// The success or failure line every action reports. It has an icon and words,
/// is announced to screen readers, and can be dismissed.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.kind, required this.message, this.onDismiss, this.dismissLabel})
      : assert(onDismiss == null || dismissLabel != null, 'A dismiss button needs its label');

  final FeedbackKind kind;
  final String message;
  final VoidCallback? onDismiss;
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final IconData icon;
    final Color color;
    switch (kind) {
      case FeedbackKind.success:
        icon = AppIcons.check;
        color = theme.palette.success;
      case FeedbackKind.failure:
        icon = AppIcons.error;
        color = theme.palette.error;
      case FeedbackKind.info:
        icon = AppIcons.info;
        color = theme.palette.textSecondary;
    }
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.bgSecondary,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: color, width: Strokes.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Row(
            children: <Widget>[
              AppIcon(icon, color: color),
              const SizedBox(width: Sp.sm),
              Expanded(child: Text(message, style: theme.text.footnote)),
              if (onDismiss != null)
                Pressable(
                  onPressed: onDismiss,
                  semanticLabel: dismissLabel,
                  excludeChildSemantics: true,
                  child: Center(child: AppIcon(AppIcons.close, size: IconSizes.medium, color: theme.palette.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
