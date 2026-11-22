import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'icon_chip.dart';

/// Top chrome: a back button or a brand mark at the start, the title, and
/// actions at the end. Uses start and end, so it mirrors in right-to-left.
class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.title,
    this.onBack,
    this.backLabel,
    this.brand,
    this.actions = const <Widget>[],
  }) : assert(onBack == null || backLabel != null, 'A back button needs its label');

  final String title;
  final VoidCallback? onBack;

  /// The back button's name for screen readers. Required with [onBack].
  final String? backLabel;

  /// Shown at the start when there is no back button.
  final Widget? brand;
  final List<Widget> actions;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Widget? leading = onBack != null
        ? IconChip(icon: rtl ? AppIcons.forward : AppIcons.back, semanticLabel: backLabel!, onPressed: onBack)
        : brand;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[leading, const SizedBox(width: Sp.sm)],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.text.title2),
              ),
            ),
            for (final Widget a in actions) ...<Widget>[const SizedBox(width: Sp.xs), a],
          ],
        ),
      ),
    );
  }
}
