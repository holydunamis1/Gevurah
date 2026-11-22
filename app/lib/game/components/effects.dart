import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../tuning.dart';

enum EffectKind { impact, stars, perfect }

/// A short-lived effect: an impact flash, a burst of stars, or a ring for a
/// perfect response. It removes itself when finished. With Reduce Motion it is
/// a fixed-size flash that fades, with no movement.
class Effect extends PositionComponent {
  Effect({required this.kind, required this.color, this.reduceMotion = false, this.radius = 60});

  final EffectKind kind;
  final Color color;
  final bool reduceMotion;
  final double radius;

  double _ms = 0;

  double get durationMs {
    if (reduceMotion) {
      return GameTuning.reducedFlashMs;
    }
    switch (kind) {
      case EffectKind.impact:
      case EffectKind.perfect:
        return GameTuning.impactMs;
      case EffectKind.stars:
        return GameTuning.starsMs;
    }
  }

  /// 0 at the start, 1 when finished.
  double get progress => (_ms / durationMs).clamp(0.0, 1.0);

  bool get finished => _ms >= durationMs;

  @override
  void update(double dt) {
    _ms += dt * 1000;
    if (finished && isMounted) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double t = progress;
    final double fade = 1 - t;
    final Paint p = Paint()..color = color.withValues(alpha: fade);
    if (reduceMotion) {
      canvas.drawCircle(Offset.zero, radius * 0.6, p);
      return;
    }
    switch (kind) {
      case EffectKind.impact:
        final Paint ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * fade + 1
          ..color = color.withValues(alpha: fade);
        canvas.drawCircle(Offset.zero, radius * (0.3 + 0.7 * t), ring);
        for (int i = 0; i < 8; i++) {
          final double a = i * math.pi / 4;
          final Offset from = Offset(math.cos(a), math.sin(a)) * (radius * (0.35 + 0.5 * t));
          final Offset to = Offset(math.cos(a), math.sin(a)) * (radius * (0.55 + 0.7 * t));
          canvas.drawLine(from, to, ring);
        }
      case EffectKind.perfect:
        final Paint ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withValues(alpha: fade);
        canvas.drawCircle(Offset.zero, radius * (0.5 + 0.9 * t), ring);
      case EffectKind.stars:
        for (int i = 0; i < 5; i++) {
          final double a = i * 2 * math.pi / 5 + t * 2;
          final Offset c = Offset(math.cos(a), math.sin(a) * 0.5) * (radius * 0.5) + Offset(0, -radius * 0.9 * t);
          _star(canvas, c, 7 * (1 - t * 0.4), p);
        }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double rr = i.isEven ? r : r * 0.45;
      final double a = -math.pi / 2 + i * math.pi / 5;
      final Offset o = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }
}
