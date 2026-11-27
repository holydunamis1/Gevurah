import 'dart:math' as math;
import 'dart:ui';

/// How a struggle's body is shaped.
enum BodyKind { round, tall, wide, blob, spiky, cloud, square }

/// The eyes: they carry most of the mood.
enum EyeStyle { wide, angry, sad, sleepy, spiral, side, closed, dot, uneven }

/// The mouth.
enum MouthStyle { frown, sly, open, wavy, zigzag, pucker, flat, smirk, smallO }

/// Small extras that make each struggle readable at a glance.
enum Extra { sweat, tear, steam, rain, zzz, questions, orb, flag, crown, cracks, hands, butterflies, spikes, blush, clock, thorns, bandage, twoTone }

/// One struggle drawn as a bright, friendly-grumpy cartoon character: a
/// colourful body, a face, a pair of fists and a few extras. Bloodless, never a
/// person, a group or a demon. Defined by data so each of the 26 is distinct.
class CharacterSpec {
  const CharacterSpec({
    required this.body,
    required this.belly,
    required this.accent,
    required this.kind,
    required this.eyes,
    required this.mouth,
    this.extras = const <Extra>[],
    this.size = 1,
  });

  final Color body;
  final Color belly;
  final Color accent;
  final BodyKind kind;
  final EyeStyle eyes;
  final MouthStyle mouth;
  final List<Extra> extras;

  /// Body scale (the final bout is bigger).
  final double size;

  static const CharacterSpec _fallback = CharacterSpec(
    body: Color(0xFF8E7CC3),
    belly: Color(0xFFC9BFE8),
    accent: Color(0xFFFFD166),
    kind: BodyKind.blob,
    eyes: EyeStyle.angry,
    mouth: MouthStyle.frown,
  );

  /// The character for [id]; an unknown id gets a neutral grumpy blob.
  static CharacterSpec forId(String id) => _all[id] ?? _fallback;

  /// Every struggle that has a drawn character.
  static Iterable<String> get ids => _all.keys;

  static const Map<String, CharacterSpec> _all = <String, CharacterSpec>{
    // Tier 1
    'fear': CharacterSpec(body: Color(0xFFB39DDB), belly: Color(0xFFE6DDFA), accent: Color(0xFF7E57C2), kind: BodyKind.round, eyes: EyeStyle.wide, mouth: MouthStyle.smallO, extras: <Extra>[Extra.sweat], size: 0.9),
    'worry': CharacterSpec(body: Color(0xFFFFD54F), belly: Color(0xFFFFF1B8), accent: Color(0xFFF57F17), kind: BodyKind.blob, eyes: EyeStyle.uneven, mouth: MouthStyle.wavy, extras: <Extra>[Extra.sweat, Extra.questions]),
    'anger': CharacterSpec(body: Color(0xFFEF5350), belly: Color(0xFFFFB4AB), accent: Color(0xFFB71C1C), kind: BodyKind.wide, eyes: EyeStyle.angry, mouth: MouthStyle.zigzag, extras: <Extra>[Extra.steam], size: 1.1),
    'impatience': CharacterSpec(body: Color(0xFFFF9800), belly: Color(0xFFFFD9A0), accent: Color(0xFFE65100), kind: BodyKind.tall, eyes: EyeStyle.side, mouth: MouthStyle.flat, extras: <Extra>[Extra.clock]),
    // Tier 2
    'loneliness': CharacterSpec(body: Color(0xFF64B5F6), belly: Color(0xFFBBDEFB), accent: Color(0xFF1565C0), kind: BodyKind.round, eyes: EyeStyle.sad, mouth: MouthStyle.frown, extras: <Extra>[Extra.tear], size: 0.9),
    'discouragement': CharacterSpec(body: Color(0xFF78909C), belly: Color(0xFFCFD8DC), accent: Color(0xFF455A64), kind: BodyKind.blob, eyes: EyeStyle.sad, mouth: MouthStyle.frown, extras: <Extra>[Extra.rain]),
    'exhaustion': CharacterSpec(body: Color(0xFF9CCC65), belly: Color(0xFFDCEDC8), accent: Color(0xFF558B2F), kind: BodyKind.wide, eyes: EyeStyle.sleepy, mouth: MouthStyle.flat, extras: <Extra>[Extra.zzz]),
    'envy': CharacterSpec(body: Color(0xFF26A69A), belly: Color(0xFFB2DFDB), accent: Color(0xFF00695C), kind: BodyKind.tall, eyes: EyeStyle.side, mouth: MouthStyle.smirk, extras: <Extra>[Extra.twoTone]),
    // Tier 3
    'doubt': CharacterSpec(body: Color(0xFF9575CD), belly: Color(0xFFD1C4E9), accent: Color(0xFF4527A0), kind: BodyKind.blob, eyes: EyeStyle.uneven, mouth: MouthStyle.wavy, extras: <Extra>[Extra.questions]),
    'temptation': CharacterSpec(body: Color(0xFFEC407A), belly: Color(0xFFF8BBD0), accent: Color(0xFFAD1457), kind: BodyKind.round, eyes: EyeStyle.side, mouth: MouthStyle.sly, extras: <Extra>[Extra.orb]),
    'rejection': CharacterSpec(body: Color(0xFF8D6E63), belly: Color(0xFFD7CCC8), accent: Color(0xFF4E342E), kind: BodyKind.round, eyes: EyeStyle.sad, mouth: MouthStyle.smallO, extras: <Extra>[Extra.hands]),
    'bitterness': CharacterSpec(body: Color(0xFF9E9D24), belly: Color(0xFFE6EE9C), accent: Color(0xFF4E5B00), kind: BodyKind.spiky, eyes: EyeStyle.angry, mouth: MouthStyle.pucker, extras: <Extra>[Extra.thorns]),
    // Tier 4
    'pride': CharacterSpec(body: Color(0xFFFFB300), belly: Color(0xFFFFE082), accent: Color(0xFFFF6F00), kind: BodyKind.wide, eyes: EyeStyle.closed, mouth: MouthStyle.smirk, extras: <Extra>[Extra.crown], size: 1.1),
    'shame': CharacterSpec(body: Color(0xFFF48FB1), belly: Color(0xFFFCE4EC), accent: Color(0xFFC2185B), kind: BodyKind.round, eyes: EyeStyle.closed, mouth: MouthStyle.wavy, extras: <Extra>[Extra.blush, Extra.hands]),
    'failure': CharacterSpec(body: Color(0xFF4DB6AC), belly: Color(0xFFB2DFDB), accent: Color(0xFF00796B), kind: BodyKind.square, eyes: EyeStyle.dot, mouth: MouthStyle.frown, extras: <Extra>[Extra.cracks, Extra.bandage]),
    'giving_up': CharacterSpec(body: Color(0xFF5C6BC0), belly: Color(0xFFC5CAE9), accent: Color(0xFF1A237E), kind: BodyKind.cloud, eyes: EyeStyle.sleepy, mouth: MouthStyle.frown, extras: <Extra>[Extra.flag], size: 1.25),
    // Trials
    'comparison': CharacterSpec(body: Color(0xFF29B6F6), belly: Color(0xFFFF8A65), accent: Color(0xFF0277BD), kind: BodyKind.wide, eyes: EyeStyle.side, mouth: MouthStyle.smirk, extras: <Extra>[Extra.twoTone]),
    'procrastination': CharacterSpec(body: Color(0xFFBCAAA4), belly: Color(0xFFEFEBE9), accent: Color(0xFF6D4C41), kind: BodyKind.wide, eyes: EyeStyle.sleepy, mouth: MouthStyle.smallO, extras: <Extra>[Extra.clock, Extra.zzz]),
    'distraction': CharacterSpec(body: Color(0xFF66BB6A), belly: Color(0xFFC8E6C9), accent: Color(0xFF2E7D32), kind: BodyKind.cloud, eyes: EyeStyle.spiral, mouth: MouthStyle.open, extras: <Extra>[Extra.butterflies]),
    'regret': CharacterSpec(body: Color(0xFF7986CB), belly: Color(0xFFC5CAE9), accent: Color(0xFF303F9F), kind: BodyKind.tall, eyes: EyeStyle.sad, mouth: MouthStyle.frown, extras: <Extra>[Extra.tear]),
    'indecision': CharacterSpec(body: Color(0xFFFFCA28), belly: Color(0xFF81D4FA), accent: Color(0xFF0288D1), kind: BodyKind.round, eyes: EyeStyle.uneven, mouth: MouthStyle.flat, extras: <Extra>[Extra.twoTone, Extra.questions]),
    'money_pressure': CharacterSpec(body: Color(0xFF43A047), belly: Color(0xFFFFE082), accent: Color(0xFFF9A825), kind: BodyKind.square, eyes: EyeStyle.wide, mouth: MouthStyle.zigzag, extras: <Extra>[Extra.sweat, Extra.orb]),
    'perfectionism': CharacterSpec(body: Color(0xFFE0E0E0), belly: Color(0xFFFFFFFF), accent: Color(0xFF616161), kind: BodyKind.square, eyes: EyeStyle.angry, mouth: MouthStyle.flat, extras: <Extra>[Extra.cracks]),
    'overwhelm': CharacterSpec(body: Color(0xFFAB47BC), belly: Color(0xFFE1BEE7), accent: Color(0xFF6A1B9A), kind: BodyKind.cloud, eyes: EyeStyle.spiral, mouth: MouthStyle.open, extras: <Extra>[Extra.sweat, Extra.questions], size: 1.15),
    'unforgiveness': CharacterSpec(body: Color(0xFF8D4E4E), belly: Color(0xFFD7A9A9), accent: Color(0xFF5D1F1F), kind: BodyKind.spiky, eyes: EyeStyle.angry, mouth: MouthStyle.flat, extras: <Extra>[Extra.thorns, Extra.steam]),
    'complaining': CharacterSpec(body: Color(0xFFFF7043), belly: Color(0xFFFFCCBC), accent: Color(0xFFBF360C), kind: BodyKind.round, eyes: EyeStyle.angry, mouth: MouthStyle.open, extras: <Extra>[Extra.steam]),
  };
}

/// What the painter needs to know about the moment.
class CharacterMood {
  const CharacterMood({this.tell = 0, this.hurt = false, this.lunge = 0, this.time = 0});

  /// 0 to 1 while the wind-up runs.
  final double tell;

  /// Eyes squeezed shut after a hit or a knockdown.
  final bool hurt;

  /// 0 to 1 through the punch.
  final double lunge;

  /// Seconds, for idle wobble.
  final double time;
}

/// Draws a [CharacterSpec]. The figure is centred on the origin and [r] is its
/// base radius; it faces left (towards the player).
abstract final class CharacterPainter {
  static void paint(Canvas canvas, CharacterSpec s, double r, CharacterMood m, {required Color glow}) {
    final double u = r * s.size;
    final Path body = _bodyPath(s.kind, u, m.time);

    // Wind-up glow behind the body.
    if (m.tell > 0) {
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * (0.10 + 0.10 * m.tell)
          ..color = glow.withValues(alpha: 0.9 * m.tell),
      );
    }
    _drawFists(canvas, s, u, m);
    canvas.drawPath(body, Paint()..color = s.body);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.05
        ..color = s.accent,
    );
    // Belly.
    canvas.drawOval(Rect.fromCenter(center: Offset(u * 0.02, u * 0.35), width: u * 1.0, height: u * 0.75), Paint()..color = s.belly.withValues(alpha: 0.85));
    if (s.extras.contains(Extra.twoTone)) {
      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(Rect.fromLTRB(0, -u * 2, u * 2, u * 2), Paint()..color = s.belly);
      canvas.restore();
    }
    _drawFace(canvas, s, u, m);
    _drawExtras(canvas, s, u, m);
  }

  static Path _bodyPath(BodyKind kind, double u, double time) {
    final Path p = Path();
    final double wob = 1 + 0.02 * math.sin(time * 3);
    switch (kind) {
      case BodyKind.round:
        p.addOval(Rect.fromCircle(center: Offset.zero, radius: u * wob));
      case BodyKind.tall:
        p.addOval(Rect.fromCenter(center: Offset.zero, width: u * 1.55 * wob, height: u * 2.3));
      case BodyKind.wide:
        p.addOval(Rect.fromCenter(center: Offset.zero, width: u * 2.3 * wob, height: u * 1.7));
      case BodyKind.square:
        p.addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: u * 1.9 * wob, height: u * 1.9), Radius.circular(u * 0.35)));
      case BodyKind.cloud:
        for (final List<double> c in const <List<double>>[
          <double>[-0.7, 0.2, 0.75],
          <double>[0.7, 0.2, 0.75],
          <double>[0.0, -0.45, 0.95],
          <double>[0.0, 0.35, 0.95],
        ]) {
          p.addOval(Rect.fromCircle(center: Offset(c[0] * u, c[1] * u), radius: c[2] * u * wob));
        }
      case BodyKind.spiky:
        const int points = 10;
        for (int i = 0; i < points * 2; i++) {
          final double a = i / (points * 2) * math.pi * 2;
          final double rr = i.isEven ? u * 1.25 : u * 0.9;
          final Offset o = Offset(math.cos(a) * rr, math.sin(a) * rr);
          if (i == 0) {
            p.moveTo(o.dx, o.dy);
          } else {
            p.lineTo(o.dx, o.dy);
          }
        }
        p.close();
      case BodyKind.blob:
        const int steps = 48;
        for (int i = 0; i <= steps; i++) {
          final double a = i / steps * math.pi * 2;
          final double rr = u * (1 + 0.10 * math.sin(3 * a + time * 2) + 0.05 * math.sin(5 * a - time));
          final Offset o = Offset(math.cos(a) * rr * 1.1, math.sin(a) * rr);
          if (i == 0) {
            p.moveTo(o.dx, o.dy);
          } else {
            p.lineTo(o.dx, o.dy);
          }
        }
        p.close();
    }
    return p;
  }

  static void _drawFists(Canvas canvas, CharacterSpec s, double u, CharacterMood m) {
    // The front fist (towards the player, on the left) cocks back during the
    // wind-up and snaps forward through the punch.
    final Paint fist = Paint()..color = s.accent;
    final Paint rim = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55);
    final double reach = m.lunge > 0 ? -u * (1.0 + 0.9 * math.sin(m.lunge * math.pi)) : u * (0.1 * m.tell);
    final Offset front = Offset(-u * 0.95 + reach - (m.tell > 0 ? -u * 0.9 * m.tell : 0), u * 0.1 - (m.tell > 0 ? u * 0.5 * m.tell : 0));
    final Offset back = Offset(u * 0.95, u * 0.25);
    for (final Offset o in <Offset>[front, back]) {
      canvas.drawCircle(o, u * 0.36, fist);
      canvas.drawCircle(o.translate(-u * 0.1, -u * 0.1), u * 0.12, rim);
    }
  }

  static void _drawFace(Canvas canvas, CharacterSpec s, double u, CharacterMood m) {
    final Paint white = Paint()..color = const Color(0xFFFFFFFF);
    final Paint ink = Paint()..color = const Color(0xFF1B1B1F);
    final Paint line = Paint()
      ..color = const Color(0xFF1B1B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.07
      ..strokeCap = StrokeCap.round;
    final double ex = u * 0.34;
    final double ey = -u * 0.18;
    final double er = u * 0.2;
    final double blink = (math.sin(m.time * 1.7) > 0.97) ? 0.1 : 1.0;

    if (m.hurt) {
      for (final double sx in <double>[-1, 1]) {
        final Offset c = Offset(sx * ex, ey);
        canvas.drawLine(c.translate(-er * 0.7, -er * 0.7), c.translate(er * 0.7, er * 0.7), line);
        canvas.drawLine(c.translate(-er * 0.7, er * 0.7), c.translate(er * 0.7, -er * 0.7), line);
      }
      canvas.drawOval(Rect.fromCenter(center: Offset(0, u * 0.38), width: u * 0.35, height: u * 0.28), ink);
      return;
    }

    for (final double sx in <double>[-1, 1]) {
      final Offset c = Offset(sx * ex, ey);
      switch (s.eyes) {
        case EyeStyle.wide:
          canvas.drawCircle(c, er * 1.25, white);
          canvas.drawCircle(c, er * 1.25, line);
          canvas.drawCircle(c.translate(0, er * 0.1), er * 0.4, ink);
        case EyeStyle.angry:
          canvas.drawCircle(c, er, white);
          canvas.drawCircle(c.translate(-sx * er * 0.1, er * 0.15), er * 0.45, ink);
          canvas.drawLine(c.translate(-sx * er * 1.3, -er * 1.5), c.translate(sx * er * 0.9, -er * 0.6), line..strokeWidth = u * 0.1);
          line.strokeWidth = u * 0.07;
        case EyeStyle.sad:
          canvas.drawCircle(c, er, white);
          canvas.drawCircle(c.translate(0, er * 0.3), er * 0.5, ink);
          canvas.drawLine(c.translate(sx * er * 1.2, -er * 1.4), c.translate(-sx * er * 1.0, -er * 0.9), line);
        case EyeStyle.sleepy:
          canvas.drawArc(Rect.fromCircle(center: c, radius: er), 0, math.pi, false, line);
          canvas.drawLine(c.translate(-er, 0), c.translate(er, 0), line);
        case EyeStyle.spiral:
          canvas.drawCircle(c, er * 1.1, white);
          final Path sp = Path()..moveTo(c.dx, c.dy);
          for (int i = 1; i <= 24; i++) {
            final double a = i * 0.55;
            sp.lineTo(c.dx + math.cos(a) * er * 0.045 * i, c.dy + math.sin(a) * er * 0.045 * i);
          }
          canvas.drawPath(sp, line..strokeWidth = u * 0.04);
          line.strokeWidth = u * 0.07;
        case EyeStyle.side:
          canvas.drawCircle(c, er, white);
          canvas.drawCircle(c.translate(-er * 0.5, 0), er * 0.45, ink);
        case EyeStyle.closed:
          canvas.drawArc(Rect.fromCircle(center: c.translate(0, er * 0.4), radius: er), math.pi, math.pi, false, line);
        case EyeStyle.dot:
          canvas.drawCircle(c, er * 0.45, ink);
        case EyeStyle.uneven:
          final double k = sx < 0 ? 1.3 : 0.8;
          canvas.drawCircle(c, er * k, white);
          canvas.drawCircle(c, er * k, line..strokeWidth = u * 0.05);
          line.strokeWidth = u * 0.07;
          canvas.drawCircle(c.translate(0, er * 0.1), er * k * 0.4, ink);
      }
      if (s.eyes == EyeStyle.wide || s.eyes == EyeStyle.angry || s.eyes == EyeStyle.side) {
        if (blink < 1) {
          canvas.drawLine(c.translate(-er, 0), c.translate(er, 0), line);
        }
      }
    }

    final Offset mc = Offset(0, u * 0.42);
    final double mw = u * 0.45;
    switch (s.mouth) {
      case MouthStyle.frown:
        canvas.drawArc(Rect.fromCenter(center: mc.translate(0, mw * 0.4), width: mw * 1.6, height: mw), math.pi, math.pi, false, line);
      case MouthStyle.sly:
        canvas.drawArc(Rect.fromCenter(center: mc.translate(mw * 0.2, -mw * 0.2), width: mw * 1.8, height: mw), 0, math.pi, false, line);
      case MouthStyle.open:
        canvas.drawOval(Rect.fromCenter(center: mc, width: mw * 1.2, height: mw * 1.1), ink);
      case MouthStyle.wavy:
        final Path w = Path()..moveTo(mc.dx - mw, mc.dy);
        for (int i = 1; i <= 4; i++) {
          w.quadraticBezierTo(mc.dx - mw + (i - 0.5) * mw * 0.5, mc.dy + (i.isOdd ? -1 : 1) * mw * 0.3, mc.dx - mw + i * mw * 0.5, mc.dy);
        }
        canvas.drawPath(w, line);
      case MouthStyle.zigzag:
        final Path z = Path()..moveTo(mc.dx - mw, mc.dy);
        for (int i = 1; i <= 6; i++) {
          z.lineTo(mc.dx - mw + i * mw / 3, mc.dy + (i.isOdd ? -mw * 0.3 : mw * 0.1));
        }
        canvas.drawPath(z, line);
      case MouthStyle.pucker:
        canvas.drawCircle(mc, mw * 0.3, ink);
      case MouthStyle.flat:
        canvas.drawLine(mc.translate(-mw * 0.8, 0), mc.translate(mw * 0.8, 0), line);
      case MouthStyle.smirk:
        canvas.drawArc(Rect.fromCenter(center: mc, width: mw * 1.6, height: mw * 0.9), 0.2, math.pi * 0.7, false, line);
      case MouthStyle.smallO:
        canvas.drawOval(Rect.fromCenter(center: mc, width: mw * 0.5, height: mw * 0.6), ink);
    }
  }

  static void _drawExtras(Canvas canvas, CharacterSpec s, double u, CharacterMood m) {
    final Paint fill = Paint()..color = s.accent;
    final Paint pale = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    final Paint blue = Paint()..color = const Color(0xFF4FC3F7);
    final Paint line = Paint()
      ..color = s.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.07
      ..strokeCap = StrokeCap.round;
    final double bob = math.sin(m.time * 4) * u * 0.04;
    for (final Extra e in s.extras) {
      switch (e) {
        case Extra.sweat:
          canvas.drawOval(Rect.fromCenter(center: Offset(u * 0.85, -u * 0.55 + bob), width: u * 0.2, height: u * 0.32), blue);
        case Extra.tear:
          canvas.drawOval(Rect.fromCenter(center: Offset(-u * 0.45, u * 0.12 + bob * 2), width: u * 0.15, height: u * 0.28), blue);
        case Extra.steam:
          for (final double sx in <double>[-0.5, 0.5]) {
            canvas.drawCircle(Offset(sx * u, -u * 1.15 + bob), u * 0.16, pale);
            canvas.drawCircle(Offset(sx * u * 1.2, -u * 1.4 + bob), u * 0.1, pale);
          }
        case Extra.rain:
          canvas.drawOval(Rect.fromCenter(center: Offset(0, -u * 1.3), width: u * 1.6, height: u * 0.6), Paint()..color = const Color(0xFF90A4AE));
          for (int i = -1; i <= 1; i++) {
            canvas.drawLine(Offset(i * u * 0.4, -u * 0.95 + bob), Offset(i * u * 0.4 - u * 0.05, -u * 0.7 + bob), line..color = const Color(0xFF4FC3F7));
          }
          line.color = s.accent;
        case Extra.zzz:
          canvas.drawLine(Offset(u * 0.6, -u * 0.9 + bob), Offset(u * 0.9, -u * 0.9 + bob), line);
          canvas.drawLine(Offset(u * 0.9, -u * 0.9 + bob), Offset(u * 0.6, -u * 0.65 + bob), line);
          canvas.drawLine(Offset(u * 0.6, -u * 0.65 + bob), Offset(u * 0.9, -u * 0.65 + bob), line);
        case Extra.questions:
          canvas.drawCircle(Offset(u * 0.75, -u * 1.0 + bob), u * 0.14, fill);
          canvas.drawCircle(Offset(-u * 0.8, -u * 0.9 - bob), u * 0.1, fill);
          canvas.drawArc(Rect.fromCircle(center: Offset(u * 0.75, -u * 1.0 + bob), radius: u * 0.2), math.pi, math.pi * 1.4, false, line);
        case Extra.orb:
          canvas.drawCircle(Offset(u * 0.9, -u * 0.2 + bob * 2), u * 0.22, Paint()..color = const Color(0xFFFFEB3B));
          canvas.drawCircle(Offset(u * 0.9, -u * 0.2 + bob * 2), u * 0.32, Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.3));
        case Extra.flag:
          canvas.drawLine(Offset(u * 0.4, -u * 1.0), Offset(u * 0.4, -u * 1.8), line);
          canvas.drawRect(Rect.fromLTWH(u * 0.4, -u * 1.8, u * 0.7, u * 0.45), Paint()..color = const Color(0xFFFFFFFF));
        case Extra.crown:
          final Path c = Path()
            ..moveTo(-u * 0.45, -u * 0.95)
            ..lineTo(-u * 0.45, -u * 1.35)
            ..lineTo(-u * 0.2, -u * 1.15)
            ..lineTo(0, -u * 1.45)
            ..lineTo(u * 0.2, -u * 1.15)
            ..lineTo(u * 0.45, -u * 1.35)
            ..lineTo(u * 0.45, -u * 0.95)
            ..close();
          canvas.drawPath(c, Paint()..color = const Color(0xFFFFD54F));
          canvas.drawPath(c, line);
        case Extra.cracks:
          canvas.drawLine(Offset(-u * 0.1, -u * 0.9), Offset(u * 0.1, -u * 0.55), line);
          canvas.drawLine(Offset(u * 0.1, -u * 0.55), Offset(-u * 0.05, -u * 0.3), line);
        case Extra.hands:
          for (final double sx in <double>[-1, 1]) {
            canvas.drawCircle(Offset(sx * u * 0.38, -u * 0.1), u * 0.26, fill);
          }
        case Extra.butterflies:
          for (final double sx in <double>[-1, 1]) {
            final Offset c = Offset(sx * u * 0.95, -u * 0.95 + bob * sx);
            canvas.drawOval(Rect.fromCenter(center: c.translate(-u * 0.1, 0), width: u * 0.22, height: u * 0.3), fill);
            canvas.drawOval(Rect.fromCenter(center: c.translate(u * 0.1, 0), width: u * 0.22, height: u * 0.3), fill);
          }
        case Extra.spikes:
          break;
        case Extra.blush:
          for (final double sx in <double>[-1, 1]) {
            canvas.drawOval(Rect.fromCenter(center: Offset(sx * u * 0.62, u * 0.12), width: u * 0.3, height: u * 0.18), Paint()..color = const Color(0xFFFF5252).withValues(alpha: 0.55));
          }
        case Extra.clock:
          canvas.drawCircle(Offset(0, u * 0.78), u * 0.2, pale);
          canvas.drawCircle(Offset(0, u * 0.78), u * 0.2, line);
          canvas.drawLine(Offset(0, u * 0.78), Offset(0, u * 0.66), line);
          canvas.drawLine(Offset(0, u * 0.78), Offset(u * 0.1, u * 0.78), line);
        case Extra.thorns:
          for (int i = 0; i < 4; i++) {
            final double a = -math.pi / 2 + (i - 1.5) * 0.55;
            canvas.drawLine(Offset(math.cos(a) * u * 1.0, math.sin(a) * u * 1.0), Offset(math.cos(a) * u * 1.35, math.sin(a) * u * 1.35), line..strokeWidth = u * 0.1);
          }
          line.strokeWidth = u * 0.07;
        case Extra.bandage:
          canvas.save();
          canvas.rotate(-0.5);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(u * 0.55, -u * 0.62), width: u * 0.5, height: u * 0.2), Radius.circular(u * 0.05)), Paint()..color = const Color(0xFFFFE0B2));
          canvas.restore();
        case Extra.twoTone:
          break;
      }
    }
  }
}
