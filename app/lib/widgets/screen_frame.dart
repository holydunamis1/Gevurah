import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// The shape of every screen: safe area, nav bar, content, then the bottom ad
/// slot. The ad slot is passed in and collapses to nothing when there is no ad.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.navBar, required this.child, this.adSlot});

  final Widget navBar;
  final Widget child;
  final Widget? adSlot;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.of(context).palette.bgPrimary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            navBar,
            Expanded(child: child),
            if (adSlot != null) adSlot!,
          ],
        ),
      ),
    );
  }
}
