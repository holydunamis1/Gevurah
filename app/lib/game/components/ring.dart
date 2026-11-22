import 'dart:ui';

import 'package:flame/components.dart';

import '../../theme/tokens.dart';
import '../tuning.dart';

/// The static scene: a soft light from above, the floor, three ropes and two
/// corner posts. Flat fills and thin lines only. It never moves.
class Ring extends PositionComponent {
  Ring({required this.palette});

  final AppPalette palette;

  @override
  void render(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final double floor = h * GameTuning.floorY;

    // Light from above: a soft ellipse, not a gradient wash.
    final Paint light = Paint()..color = palette.tellGlow.withValues(alpha: 0.08);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, floor * 0.55), width: w * 0.95, height: floor * 0.9), light);

    // Floor.
    canvas.drawRect(Rect.fromLTRB(0, floor, w, h), Paint()..color = palette.bgTertiary);
    canvas.drawLine(Offset(0, floor), Offset(w, floor), Paint()..color = palette.hairline..strokeWidth = Strokes.hairline);

    // Ropes between two posts.
    final Paint rope = Paint()
      ..color = palette.accent.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    final double top = floor - h * 0.34;
    for (int i = 0; i < 3; i++) {
      final double y = top + i * (h * 0.34 / 3);
      canvas.drawLine(Offset(w * 0.04, y), Offset(w * 0.96, y), rope);
    }
    final Paint post = Paint()..color = palette.textTertiary;
    for (final double x in <double>[w * 0.04, w * 0.96]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x - 4, top - 8, x + 4, floor), const Radius.circular(3)),
        post,
      );
    }
  }
}
