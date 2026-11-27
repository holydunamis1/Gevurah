import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../theme/tokens.dart';
import '../tuning.dart';

enum FighterPose { idle, guard, slip, jab, combo, stagger }

/// The player: a neutral silhouette made of a head, a body and two arms with
/// gloves. Poses blend over [GameTuning.poseBlendMs]. Facing right; the scene
/// does not mirror in right-to-left languages.
class Fighter extends PositionComponent {
  Fighter({required this.palette, this.reduceMotion = false});

  final AppPalette palette;
  final bool reduceMotion;

  FighterPose _from = FighterPose.idle;
  FighterPose _pose = FighterPose.idle;
  double _poseMs = 0;
  double _holdMs = 0;
  double _clock = 0;

  FighterPose get pose => _pose;

  /// 0 when a pose has just begun, 1 once fully blended.
  double get blend => reduceMotion ? 1 : (_poseMs / GameTuning.poseBlendMs).clamp(0.0, 1.0);

  /// Shows a pose, then returns to idle after [holdMs] (a stagger holds longer).
  void show(FighterPose pose, {double? holdMs}) {
    _from = _pose;
    _pose = pose;
    _poseMs = 0;
    _holdMs = pose == FighterPose.idle ? 0 : (holdMs ?? (pose == FighterPose.stagger ? GameTuning.staggerMs : GameTuning.poseHoldMs));
  }

  @override
  void update(double dt) {
    final double ms = dt * 1000;
    _clock += ms;
    _poseMs += ms;
    if (_pose != FighterPose.idle && _poseMs >= _holdMs) {
      show(FighterPose.idle);
    }
  }

  // Each pose: body lean, then the front glove's (x, y) and the back glove's (x, y),
  // all as fractions of the figure's height from the shoulder (y grows downward).
  static const Map<FighterPose, List<double>> _targets = <FighterPose, List<double>>{
    FighterPose.idle: <double>[0.00, 0.20, 0.02, 0.10, 0.08],
    FighterPose.guard: <double>[0.02, 0.12, -0.12, 0.06, -0.10],
    FighterPose.slip: <double>[-0.14, 0.14, 0.00, 0.06, 0.04],
    FighterPose.jab: <double>[0.06, 0.55, -0.04, 0.10, 0.06],
    FighterPose.combo: <double>[0.09, 0.60, -0.04, 0.42, 0.00],
    FighterPose.stagger: <double>[-0.12, -0.05, 0.16, -0.10, 0.20],
  };

  List<double> _lerp() {
    final List<double> a = _targets[_from]!;
    final List<double> b = _targets[_pose]!;
    final double t = blend;
    return <double>[for (int i = 0; i < a.length; i++) a[i] + (b[i] - a[i]) * t];
  }

  /// The blended lean and glove positions, for tests.
  List<double> get shape => _lerp();

  @override
  void render(Canvas canvas) {
    final double h = size.y;
    final List<double> s = _lerp();
    final double breathe = reduceMotion ? 0 : (_pose == FighterPose.idle ? 0.012 * h * math.sin(_clock / 420) : 0);
    final double lean = s[0] * h;
    final Offset hip = Offset(size.x / 2 + lean * 0.3, h);
    final Offset shoulder = Offset(size.x / 2 + lean, h * 0.42 + breathe);
    final Offset head = Offset(size.x / 2 + lean * 1.2, h * 0.24 + breathe);

    const Color skin = Color(0xFFFFC999);
    const Color shirt = Color(0xFF1E88E5);
    const Color shorts = Color(0xFFFFC107);
    const Color red = Color(0xFFE53935);
    const Color ink = Color(0xFF1B1B1F);
    final double hr = h * 0.11;

    // Legs and shorts.
    final Paint leg = Paint()
      ..color = skin
      ..strokeWidth = h * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(hip.dx - h * 0.06, hip.dy - h * 0.18), Offset(hip.dx - h * 0.08, h), leg);
    canvas.drawLine(Offset(hip.dx + h * 0.06, hip.dy - h * 0.18), Offset(hip.dx + h * 0.10, h), leg);
    // Torso.
    canvas.drawLine(
      hip.translate(0, -h * 0.12),
      shoulder,
      Paint()
        ..color = shirt
        ..strokeWidth = h * 0.20
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: hip.translate(0, -h * 0.17), width: h * 0.24, height: h * 0.12), Radius.circular(h * 0.04)),
      Paint()..color = shorts,
    );

    // Head: skin, headband, big friendly face.
    canvas.drawCircle(head, hr, Paint()..color = skin);
    canvas.drawArc(Rect.fromCircle(center: head, radius: hr), math.pi, math.pi, true, Paint()..color = const Color(0xFF5D4037));
    canvas.drawRect(Rect.fromLTWH(head.dx - hr, head.dy - hr * 0.35, hr * 2, hr * 0.28), Paint()..color = red);
    final Paint line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.012
      ..strokeCap = StrokeCap.round;
    final bool dazed = _pose == FighterPose.stagger;
    final double ex = hr * 0.38;
    for (final double sx in <double>[0.15, 0.85]) {
      final Offset c = Offset(head.dx - hr + hr * 2 * sx, head.dy + hr * 0.15);
      if (dazed) {
        canvas.drawLine(c.translate(-ex * 0.4, -ex * 0.4), c.translate(ex * 0.4, ex * 0.4), line);
        canvas.drawLine(c.translate(-ex * 0.4, ex * 0.4), c.translate(ex * 0.4, -ex * 0.4), line);
      } else {
        canvas.drawCircle(c, ex * 0.45, Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawCircle(c.translate(ex * 0.15, 0), ex * 0.25, Paint()..color = ink);
      }
    }
    final Offset mc = head.translate(hr * 0.1, hr * 0.62);
    if (dazed) {
      canvas.drawOval(Rect.fromCenter(center: mc, width: hr * 0.3, height: hr * 0.25), Paint()..color = ink);
    } else {
      canvas.drawArc(Rect.fromCenter(center: mc.translate(0, -hr * 0.1), width: hr * 0.7, height: hr * 0.45), 0.2, math.pi - 0.4, false, line);
    }

    // Arms and big red gloves.
    final Paint arm = Paint()
      ..color = skin
      ..strokeWidth = h * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 2; i++) {
      final Offset fist = Offset(shoulder.dx + s[1 + i * 2] * h, shoulder.dy + s[2 + i * 2] * h);
      canvas.drawLine(shoulder, fist, arm);
      canvas.drawCircle(fist, h * 0.085, Paint()..color = red);
      canvas.drawCircle(fist.translate(-h * 0.02, -h * 0.025), h * 0.025, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6));
      canvas.drawRect(Rect.fromCenter(center: fist.translate(-h * 0.06, 0), width: h * 0.03, height: h * 0.07), Paint()..color = const Color(0xFFFFFFFF));
    }
  }
}
