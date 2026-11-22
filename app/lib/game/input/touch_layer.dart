import 'package:flutter/widgets.dart';

import '../../core/input/input_strategy.dart';
import '../../core/input/tap_swipe_strategy.dart';

/// Turns touches into timestamped gestures for the fight controller. A tap is
/// stamped when the finger lands (that is the moment the player chose); a
/// sideways swipe is stamped when it passes the swipe distance. Timestamps come
/// from [nowMs], the same clock the controller runs on, read at the instant the
/// touch arrives, so frame rate does not blur them.
class FightTouchLayer extends StatefulWidget {
  const FightTouchLayer({super.key, required this.onGesture, required this.nowMs, required this.child});

  final void Function(RawGesture gesture) onGesture;
  final double Function() nowMs;
  final Widget child;

  @override
  State<FightTouchLayer> createState() => _FightTouchLayerState();
}

class _Touch {
  _Touch(this.start, this.startMs);

  final Offset start;
  final double startMs;
  bool fired = false;
}

class _FightTouchLayerState extends State<FightTouchLayer> {
  final Map<int, _Touch> _touches = <int, _Touch>{};

  void _down(PointerDownEvent e) {
    _touches[e.pointer] = _Touch(e.position, widget.nowMs());
  }

  void _move(PointerMoveEvent e) {
    final _Touch? t = _touches[e.pointer];
    if (t == null || t.fired) {
      return;
    }
    final Offset d = e.position - t.start;
    if (d.dx.abs() >= InputTuning.minSwipePx || d.dy.abs() >= InputTuning.minSwipePx) {
      t.fired = true;
      final double now = widget.nowMs();
      widget.onGesture(RawGesture.swipe(now, dx: d.dx, dy: d.dy, durationMs: now - t.startMs));
    }
  }

  void _up(PointerUpEvent e) {
    final _Touch? t = _touches.remove(e.pointer);
    if (t != null && !t.fired) {
      widget.onGesture(RawGesture.tap(t.startMs));
    }
  }

  void _cancel(PointerCancelEvent e) => _touches.remove(e.pointer);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: widget.child,
    );
  }
}
