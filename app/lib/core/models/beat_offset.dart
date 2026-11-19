import 'exchange_outcome.dart';

/// Default timing windows in milliseconds, either side of the beat. The game
/// layer's tuning file reads these; cards and stances adjust them in the core.
abstract final class TimingWindows {
  static const double perfectMs = 50;
  static const double goodMs = 120;

  /// Added to every window when the Timing assist setting is on.
  static const double assistMs = 40;
}

/// How far a response landed from the beat, in milliseconds. Negative is
/// early, positive is late. This is the only timing type the core sees: the
/// game converts input timestamps to beat offsets, so frame time never
/// enters the rules.
class BeatOffset {
  const BeatOffset(this.ms);

  final double ms;

  double get abs => ms.abs();

  /// Judges the offset against the given windows (milliseconds either side).
  Quality quality({
    double perfectMs = TimingWindows.perfectMs,
    double goodMs = TimingWindows.goodMs,
  }) {
    final double a = abs;
    if (a <= perfectMs) {
      return Quality.perfect;
    }
    if (a <= goodMs) {
      return Quality.good;
    }
    return Quality.miss;
  }

  Map<String, Object?> toJson() => <String, Object?>{'ms': ms};

  factory BeatOffset.fromJson(Map<String, Object?> json) {
    final Object? v = json['ms'];
    if (v is num) {
      return BeatOffset(v.toDouble());
    }
    throw FormatException('Expected a number at "ms", got $v');
  }

  @override
  bool operator ==(Object other) => other is BeatOffset && other.ms == ms;

  @override
  int get hashCode => ms.hashCode;

  @override
  String toString() => 'BeatOffset(${ms}ms)';
}
