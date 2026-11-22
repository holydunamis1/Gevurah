import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'primary_button.dart';

/// One dialog button.
class AppDialogAction {
  const AppDialogAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// A confirmation dialog: radius 16, a title, a message, one primary action and
/// an optional secondary one. Destructive confirmations should word the
/// primary action by what it does.
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.message, required this.primary, this.secondary});

  final String title;
  final String message;
  final AppDialogAction primary;
  final AppDialogAction? secondary;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.palette.bgSecondary,
            borderRadius: BorderRadius.circular(Radii.dialog),
            border: Border.all(color: theme.palette.hairline, width: Strokes.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(title, style: theme.text.title1),
                const SizedBox(height: Sp.sm),
                Text(message, style: theme.text.body.copyWith(color: theme.palette.textSecondary)),
                const SizedBox(height: Sp.lg),
                PrimaryButton(label: primary.label, onPressed: primary.onPressed),
                if (secondary != null)
                  Pressable(
                    onPressed: secondary!.onPressed,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                        child: Text(secondary!.label, style: theme.text.callout.copyWith(color: theme.palette.accent)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [dialog] centred over a dimmed barrier. Instant with Reduce Motion.
Future<T?> showAppDialog<T>(BuildContext context, {required AppDialog dialog, required String barrierLabel, bool dismissible = true}) {
  final AppTheme theme = AppTheme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: barrierLabel,
    barrierColor: const Color(0x8A000000),
    transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
    pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> s) {
      return AppTheme(
        palette: theme.palette,
        text: theme.text,
        child: Center(child: Padding(padding: const EdgeInsets.all(Sp.md), child: dialog)),
      );
    },
    transitionBuilder: (BuildContext ctx, Animation<double> a, Animation<double> s, Widget child) =>
        FadeTransition(opacity: a, child: child),
  );
}
