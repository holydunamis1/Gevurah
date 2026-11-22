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

    final Paint body = Paint()
      ..color = palette.textPrimary
      ..strokeWidth = h * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(hip, shoulder, body);
    canvas.drawCircle(head, h * 0.085, Paint()..color = palette.textPrimary);

    final Paint arm = Paint()
      ..color = palette.textSecondary
      ..strokeWidth = h * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint glove = Paint()..color = palette.accent;
    for (int i = 0; i < 2; i++) {
      final Offset fist = Offset(shoulder.dx + s[1 + i * 2] * h, shoulder.dy + s[2 + i * 2] * h);
      canvas.drawLine(shoulder, fist, arm);
      canvas.drawCircle(fist, h * 0.06, glove);
    }
  }
}
