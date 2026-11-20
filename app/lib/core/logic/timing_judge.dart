import '../models/beat_offset.dart';
import '../models/exchange_outcome.dart';
import 'modifiers.dart';

/// The two window widths for one input, in ms either side of the beat.
class Windows {
  const Windows({required this.perfectMs, required this.goodMs});

  final double perfectMs;
  final double goodMs;

  @override
  bool operator ==(Object other) => other is Windows && other.perfectMs == perfectMs && other.goodMs == goodMs;

  @override
  int get hashCode => Object.hash(perfectMs, goodMs);

  @override
  String toString() => 'Windows($perfectMs, $goodMs)';
}

/// Turns a beat offset into Perfect, Good or Miss. Frame time never enters:
/// the game converts input timestamps to beat offsets before this runs.
abstract final class TimingJudge {
  /// The narrowest a window may become, in ms.
  static const double minWindowMs = 10;

  /// How much empty Stamina narrows guard windows (30 percent).
  static const double emptyStaminaFactor = 0.7;

  /// Windows for a guard or slip response.
  static Windows responseWindows(
    Modifiers m, {
    required bool isGuard,
    bool assist = false,
    bool staminaEmpty = false,
  }) {
    double perfect = TimingWindows.perfectMs;
    double good = TimingWindows.goodMs;
    if (assist) {
      perfect += TimingWindows.assistMs;
      good += TimingWindows.assistMs;
    }
    if (isGuard) {
      perfect += m.guardWindowDeltaMs;
      good += m.guardWindowDeltaMs;
      if (staminaEmpty) {
        perfect *= emptyStaminaFactor;
        good *= emptyStaminaFactor;
      }
    }
    return _clamp(perfect, good);
  }

  /// Windows for a strike or combo beat.
  static Windows strikeWindows(Modifiers m, {bool assist = false}) {
    double perfect = TimingWindows.perfectMs;
    double good = TimingWindows.goodMs;
    if (assist) {
      perfect += TimingWindows.assistMs;
      good += TimingWindows.assistMs;
    }
    perfect += m.strikeWindowDeltaMs;
    good += m.strikeWindowDeltaMs;
    return _clamp(perfect, good);
  }

  /// Judges [offset] against [windows].
  static Quality judge(BeatOffset offset, Windows windows) {
    return offset.quality(perfectMs: windows.perfectMs, goodMs: windows.goodMs);
  }

  static Windows _clamp(double perfect, double good) {
    final double p = perfect < minWindowMs ? minWindowMs : perfect;
    final double g = good < p ? p : good;
    return Windows(perfectMs: p, goodMs: g);
  }
}
