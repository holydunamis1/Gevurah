import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The sheet surface: bgSecondary, 20 radius on top only, a grab handle and an
/// optional title.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        border: Border(top: BorderSide(color: theme.palette.hairline, width: Strokes.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: theme.palette.textTertiary, borderRadius: BorderRadius.circular(Sp.xs)),
                  child: const SizedBox(width: Sp.xxl, height: Sp.xs),
                ),
              ),
              if (title != null) ...<Widget>[
                const SizedBox(height: Sp.md),
                Semantics(header: true, child: Text(title!, style: theme.text.title1)),
              ],
              const SizedBox(height: Sp.md),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [builder] as a sheet from the bottom: 400 ms ease-out, instant with
/// Reduce Motion. Tapping outside closes it unless [dismissible] is false.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required String barrierLabel,
  bool dismissible = true,
}) {
  final AppTheme theme = AppTheme.of(context);
  final bool reduce = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: barrierLabel,
    barrierColor: const Color(0x8A000000),
    transitionDuration: reduce ? Duration.zero : const Duration(milliseconds: 400),
    pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> s) {
      return AppTheme(
        palette: theme.palette,
        text: theme.text,
        child: Align(alignment: Alignment.bottomCenter, child: builder(ctx)),
      );
    },
    transitionBuilder: (BuildContext ctx, Animation<double> a, Animation<double> s, Widget child) {
      final Animation<double> eased = CurvedAnimation(parent: a, curve: Curves.easeOut);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(eased),
        child: child,
      );
    },
  );
}
