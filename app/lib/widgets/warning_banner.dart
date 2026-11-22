import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// A persistent notice such as "Progress could not be saved", with an optional
/// action such as Retry. Warning icon plus words, never colour alone.
class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.message, this.actionLabel, this.onAction})
      : assert((actionLabel == null) == (onAction == null), 'An action needs both a label and a handler');

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.bgTertiary,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: theme.palette.warning, width: Strokes.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Row(
            children: <Widget>[
              AppIcon(AppIcons.warning, color: theme.palette.warning),
              const SizedBox(width: Sp.sm),
              Expanded(child: Text(message, style: theme.text.footnote)),
              if (onAction != null) ...<Widget>[
                const SizedBox(width: Sp.sm),
                Pressable(
                  onPressed: onAction,
                  minWidth: 0,
                  child: Center(child: Text(actionLabel!, style: theme.text.callout.copyWith(color: theme.palette.accent))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
