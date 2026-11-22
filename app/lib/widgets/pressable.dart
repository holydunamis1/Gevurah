import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Shared press behaviour: opacity only (no ripple, no elevation, no scale),
/// a 48 by 48 minimum hit area and button semantics. With Reduce Motion on the
/// change is instant.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.pressedOpacity = 0.7,
    this.disabledOpacity = 0.4,
    this.minWidth = IconSizes.target,
    this.minHeight = IconSizes.target,
    this.excludeChildSemantics = false,
  });

  final Widget child;

  /// Null means disabled: not tappable and drawn dimmed.
  final VoidCallback? onPressed;

  /// Read by screen readers. Leave null when the child's own text is the label.
  final String? semanticLabel;

  final double pressedOpacity;
  final double disabledOpacity;
  final double minWidth;
  final double minHeight;

  /// True when [semanticLabel] replaces whatever the child would say.
  final bool excludeChildSemantics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double opacity = !_enabled ? widget.disabledOpacity : (_pressed ? widget.pressedOpacity : 1);
    final Duration duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (TapDownDetails _) => _set(true) : null,
        onTapUp: _enabled ? (TapUpDetails _) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth, minHeight: widget.minHeight),
          child: AnimatedOpacity(opacity: opacity, duration: duration, curve: Curves.easeOut, child: widget.child),
        ),
      ),
    );
  }
}
