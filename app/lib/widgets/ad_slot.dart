import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The bottom banner slot. It draws nothing at all (no height, border or fill)
/// unless an ad is ready: not while loading, not after a failure, not when ads
/// are removed or hidden, and not while the keyboard is open.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, required this.visible, required this.banner, this.height = 50});

  /// The ad decision: consent, flags and Remove Ads, from the ad provider.
  final bool visible;

  /// The platform banner, or null while none is loaded.
  final Widget? banner;

  /// The reserved adaptive banner height, used only when shown.
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (!visible || banner == null || keyboardOpen) {
      return const SizedBox.shrink();
    }
    final AppTheme theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgPrimary,
        border: Border(top: BorderSide(color: theme.palette.hairline, width: Strokes.hairline)),
      ),
      child: SizedBox(height: height, child: Center(child: banner)),
    );
  }
}
