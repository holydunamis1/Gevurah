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

    // Bright sky-blue backdrop with a warm spotlight.
    canvas.drawRect(Rect.fromLTRB(0, 0, w, floor), Paint()..color = const Color(0xFF7EC8FF));
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, floor * 0.55), width: w * 1.0, height: floor * 0.95), Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.55));
    // Cheerful crowd dots.
    final Paint dot = Paint();
    const List<Color> crowd = <Color>[Color(0xFFFF8A65), Color(0xFFFFD54F), Color(0xFFBA68C8), Color(0xFF81C784)];
    for (int i = 0; i < 14; i++) {
      dot.color = crowd[i % crowd.length].withValues(alpha: 0.8);
      canvas.drawCircle(Offset(w * (0.05 + i * 0.07), floor * (0.12 + (i.isEven ? 0.0 : 0.05))), w * 0.022, dot);
    }

    // Canvas floor.
    canvas.drawRect(Rect.fromLTRB(0, floor, w, h), Paint()..color = const Color(0xFFFFB74D));
    canvas.drawLine(Offset(0, floor), Offset(w, floor), Paint()..color = const Color(0xFFE65100)..strokeWidth = 4);

    // Three bright ropes between two corner posts.
    const List<Color> ropes = <Color>[Color(0xFFE53935), Color(0xFFFFFFFF), Color(0xFF1E88E5)];
    final double top = floor - h * 0.34;
    for (int i = 0; i < 3; i++) {
      final double y = top + i * (h * 0.34 / 3);
      canvas.drawLine(Offset(w * 0.04, y), Offset(w * 0.96, y), Paint()..color = ropes[i]..strokeWidth = 5..strokeCap = StrokeCap.round);
    }
    final Paint post = Paint()..color = const Color(0xFF455A64);
    for (final double x in <double>[w * 0.04, w * 0.96]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x - 6, top - 10, x + 6, floor), const Radius.circular(4)),
        post,
      );
    }
  }
}
