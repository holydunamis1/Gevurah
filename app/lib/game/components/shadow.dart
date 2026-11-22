import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../theme/tokens.dart';
import '../tuning.dart';

enum ShadowState { idle, tell, lunge, flinch, down, dissolve, rise }

/// The shape of one struggle's shadow, made from its id alone: the same id
/// always gives the same form and different ids give different ones. Always
/// abstract: no face, no limbs, never a person.
class ShadowShape {
  const ShadowShape({required this.lobes, required this.wobble, required this.skew, required this.phase, required this.width});

  factory ShadowShape.forId(String id) {
    int h = 0x811C9DC5;
    for (final int c in id.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    double part(int shift) => ((h >> shift) & 0xFF) / 255.0;
    return ShadowShape(
      lobes: 3 + (h & 0x7) % 5,
      wobble: 0.10 + part(8) * 0.16,
      skew: (part(16) - 0.5) * 0.5,
      phase: part(24) * math.pi * 2,
      width: 0.75 + part(4) * 0.35,
    );
  }

  /// How many bulges the outline has (3 to 7).
  final int lobes;
  final double wobble;
  final double skew;
  final double phase;
  final double width;

  /// The outline for a form of [radius], centred on the origin.
  Path path(double radius, {double time = 0}) {
    final Path p = Path();
    const int steps = 72;
    for (int i = 0; i <= steps; i++) {
      final double a = i / steps * math.pi * 2;
      final double r = radius *
          (1 +
              wobble * math.sin(lobes * a + phase + time * 0.8) +
              wobble * 0.45 * math.sin((lobes + 2) * a - phase * 0.7 - time * 0.5) +
              skew * math.sin(a));
      final Offset o = Offset(math.cos(a) * r * width, math.sin(a) * r * 1.15);
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    return p..close();
  }

  @override
  bool operator ==(Object other) =>
      other is ShadowShape && other.lobes == lobes && other.wobble == wobble && other.skew == skew && other.phase == phase && other.width == width;

  @override
  int get hashCode => Object.hash(lobes, wobble, skew, phase, width);
}

/// The struggle: an abstract shadow form. It gathers and glows while its tell
/// runs, lunges when the move lands, flinches when hit, goes down when
/// defeated and then lifts away like a weight released. With Reduce Motion
/// every movement is replaced by a change of opacity and glow.
class Shadow extends PositionComponent {
  Shadow({required this.shape, required this.palette, this.reduceMotion = false});

  final ShadowShape shape;
  final AppPalette palette;
  final bool reduceMotion;

  ShadowState _state = ShadowState.idle;
  double _stateMs = 0;
  double _clock = 0;
  double _tell = 0;

  ShadowState get state => _state;

  /// 0 to 1 while the tell runs.
  double get tellProgress => _tell;

  double get stateMs => _stateMs;

  /// How visible the form is: 1 normally, fading to 0 as it dissolves.
  double get opacity {
    if (_state == ShadowState.dissolve) {
      return (1 - _stateMs / GameTuning.defeatLiftMs).clamp(0.0, 1.0);
    }
    return 1;
  }

  bool get dissolved => _state == ShadowState.dissolve && _stateMs >= GameTuning.defeatLiftMs;

  void _enter(ShadowState s) {
    _state = s;
    _stateMs = 0;
  }

  /// A tell is running; [progress] runs 0 to 1 up to the landing.
  void tell(double progress) {
    if (_state == ShadowState.dissolve || _state == ShadowState.down) {
      return;
    }
    if (_state != ShadowState.tell) {
      _enter(ShadowState.tell);
    }
    _tell = progress.clamp(0.0, 1.0);
  }

  void lunge() {
    if (_state != ShadowState.dissolve && _state != ShadowState.down) {
      _tell = 0;
      _enter(ShadowState.lunge);
    }
  }

  void flinch() {
    if (_state != ShadowState.dissolve && _state != ShadowState.down) {
      _tell = 0;
      _enter(ShadowState.flinch);
    }
  }

  void knockDown() {
    _tell = 0;
    _enter(ShadowState.down);
  }

  void dissolve() {
    _tell = 0;
    _enter(ShadowState.dissolve);
  }

  /// Gets back up (Failure does this once).
  void rise() {
    _tell = 0;
    _enter(ShadowState.rise);
  }

  void settle() {
    _tell = 0;
    _enter(ShadowState.idle);
  }

  @override
  void update(double dt) {
    final double ms = dt * 1000;
    _clock += ms;
    _stateMs += ms;
    if (_state == ShadowState.lunge && _stateMs >= GameTuning.lungeMs) {
      settle();
    } else if (_state == ShadowState.flinch && _stateMs >= GameTuning.flinchMs) {
      settle();
    } else if (_state == ShadowState.rise && _stateMs >= GameTuning.riseMs) {
      settle();
    }
    // A defeated (down) shadow stays down until told to dissolve.
  }

  @override
  void render(Canvas canvas) {
    final double a = opacity;
    if (a <= 0) {
      return;
    }
    final double r = size.y * 0.30;
    double dx = 0;
    double dy = 0;
    double scale = 1;
    double glow = 0;
    final double time = reduceMotion ? 0 : _clock / 1000;
    switch (_state) {
      case ShadowState.idle:
        scale = reduceMotion ? 1 : 1 + 0.02 * math.sin(_clock / 500);
      case ShadowState.tell:
        glow = _tell;
        scale = reduceMotion ? 1 : 1 + 0.10 * _tell;
      case ShadowState.lunge:
        final double t = (_stateMs / GameTuning.lungeMs).clamp(0.0, 1.0);
        glow = 1 - t;
        dx = reduceMotion ? 0 : -size.x * 0.25 * math.sin(t * math.pi);
      case ShadowState.flinch:
        final double t = (_stateMs / GameTuning.flinchMs).clamp(0.0, 1.0);
        dx = reduceMotion ? 0 : size.x * 0.08 * math.sin(t * math.pi);
      case ShadowState.down:
        dy = reduceMotion ? 0 : r * 0.55;
        scale = reduceMotion ? 1 : 0.9;
      case ShadowState.dissolve:
        final double t = (_stateMs / GameTuning.defeatLiftMs).clamp(0.0, 1.0);
        dy = reduceMotion ? 0 : r * 0.55 - size.y * 0.45 * t;
        scale = reduceMotion ? 1 : 0.9 + 0.2 * t;
      case ShadowState.rise:
        final double t = (_stateMs / GameTuning.riseMs).clamp(0.0, 1.0);
        dy = reduceMotion ? 0 : r * 0.55 * (1 - t);
    }
    canvas.save();
    canvas.translate(size.x / 2 + dx, size.y / 2 + dy);
    canvas.scale(scale);
    final Path outline = shape.path(r, time: time);
    if (glow > 0) {
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = palette.tellGlow.withValues(alpha: 0.85 * glow * a),
      );
    }
    canvas.drawPath(outline, Paint()..color = palette.shadowTint.withValues(alpha: 0.92 * a));
    canvas.restore();
  }
}
