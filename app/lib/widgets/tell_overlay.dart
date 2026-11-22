import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/models/move_def.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The visual part of a telegraph. Each kind of move has its own silhouette,
/// and the move's name is shown as text beside it, so the tell is never colour
/// alone; the sound and the haptic pulse come from the fight controller.
/// [progress] runs from 0 (the tell just began) to 1 (the move lands); the
/// caller drives it, so this widget never animates by itself.
class TellOverlay extends StatelessWidget {
  const TellOverlay({super.key, required this.kind, required this.progress, required this.label, this.size = 120});

  final MoveKind kind;
  final double progress;

  /// The move's name in the player's language, for example "Heavy swing".
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: TellPainter(kind: kind, progress: progress.clamp(0.0, 1.0), color: theme.palette.tellGlow, track: theme.palette.bgTertiary),
            ),
          ),
          const SizedBox(height: Sp.xs),
          Text(label, style: theme.text.callout),
        ],
      ),
    );
  }
}

/// Draws the silhouette and the countdown ring.
class TellPainter extends CustomPainter {
  const TellPainter({required this.kind, required this.progress, required this.color, required this.track});

  final MoveKind kind;
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = track;
    canvas.drawCircle(c, r - 2, ring);
    ring.color = color;
    ring.strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 2), -math.pi / 2, 2 * math.pi * progress, false, ring);

    final Paint fill = Paint()..color = color;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    final double u = r * 0.5;
    switch (kind) {
      case MoveKind.strike:
        canvas.drawCircle(c, u * 0.7, fill);
      case MoveKind.flurry:
        for (int i = -1; i <= 1; i++) {
          canvas.drawCircle(c + Offset(i * u * 0.75, 0), u * 0.28, fill);
        }
      case MoveKind.heavy:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: u * 1.5, height: u * 1.5), Radius.circular(u * 0.2)), fill);
      case MoveKind.ping:
        for (final Offset d in <Offset>[Offset(-u * 0.4, -u * 0.4), Offset(u * 0.4, -u * 0.4), Offset(-u * 0.4, u * 0.4), Offset(u * 0.4, u * 0.4)]) {
          canvas.drawCircle(c + d, u * 0.14, fill);
        }
      case MoveKind.fake:
        canvas.drawCircle(c, u * 0.7, line);
      case MoveKind.bait:
        final Path p = Path()
          ..moveTo(c.dx, c.dy - u * 0.8)
          ..lineTo(c.dx + u * 0.8, c.dy)
          ..lineTo(c.dx, c.dy + u * 0.8)
          ..lineTo(c.dx - u * 0.8, c.dy)
          ..close();
        canvas.drawPath(p, line);
        canvas.drawCircle(c, u * 0.15, fill);
      case MoveKind.drain:
        for (int i = 0; i < 3; i++) {
          final double half = u * (0.8 - i * 0.25);
          final double y = c.dy + (i - 1) * u * 0.5;
          canvas.drawLine(Offset(c.dx - half, y), Offset(c.dx + half, y), line);
        }
    }
  }

  @override
  bool shouldRepaint(TellPainter old) =>
      old.kind != kind || old.progress != progress || old.color != color || old.track != track;
}
