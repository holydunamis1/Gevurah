import '../models/beat_offset.dart';
import '../models/exchange_record.dart';
import 'input_strategy.dart';

/// Tuning for turning gestures into moves.
abstract final class InputTuning {
  /// A swipe must travel at least this far sideways to count as a Slip.
  static const double minSwipePx = 28;

  /// A swipe must be clearly sideways: horizontal travel at least this times vertical.
  static const double sidewaysRatio = 1.5;

  /// A swipe slower than this is a drag, not a flick, and counts as a tap only
  /// when it is also short (below [minSwipePx]); otherwise it is ignored.
  static const double maxSwipeMs = 450;

  /// A second tap within this many ms of the first makes a Combo.
  static const double comboGapMs = 260;

  /// Gestures further than this from the beat are too far to be an attempt.
  static const double attemptRangeMs = 400;
}

/// The default input: tap to Guard or Strike, swipe sideways to Slip, two taps
/// close together for a Combo.
class TapSwipeStrategy implements InputStrategy {
  double? _responseBeat;
  ResponseEvent? _response;

  double? _openingBeat;
  double? _firstTap;
  double? _secondTap;

  /// True for a gesture that is a tap (including a very short swipe).
  static bool isTap(RawGesture g) {
    if (g.dx == 0 && g.dy == 0) {
      return true;
    }
    return g.dx.abs() < InputTuning.minSwipePx && g.dy.abs() < InputTuning.minSwipePx;
  }

  /// True for a flick that is clearly sideways.
  static bool isSideSwipe(RawGesture g) {
    return g.dx.abs() >= InputTuning.minSwipePx &&
        g.dx.abs() >= g.dy.abs() * InputTuning.sidewaysRatio &&
        g.durationMs <= InputTuning.maxSwipeMs;
  }

  @override
  void beginResponse(double beatMs) {
    _responseBeat = beatMs;
    _response = null;
  }

  @override
  void beginOpening(double beatMs) {
    _openingBeat = beatMs;
    _firstTap = null;
    _secondTap = null;
  }

  @override
  ResponseEvent? onResponseGesture(RawGesture gesture) {
    final double? beat = _responseBeat;
    if (beat == null || _response != null) {
      return null;
    }
    final double offset = gesture.timestampMs - beat;
    if (offset.abs() > InputTuning.attemptRangeMs) {
      return null;
    }
    final Response? kind = isSideSwipe(gesture)
        ? Response.slip
        : isTap(gesture)
            ? Response.guard
            : null;
    if (kind == null) {
      return null;
    }
    _response = ResponseEvent(kind, BeatOffset(offset));
    return _response;
  }

  @override
  ResponseEvent? finishResponse() {
    final ResponseEvent? r = _response;
    _responseBeat = null;
    _response = null;
    return r;
  }

  @override
  OpeningEvent? onOpeningGesture(RawGesture gesture) {
    final double? beat = _openingBeat;
    if (beat == null || !isTap(gesture)) {
      return null;
    }
    if ((gesture.timestampMs - beat).abs() > InputTuning.attemptRangeMs && _firstTap == null) {
      return null;
    }
    if (_firstTap == null) {
      _firstTap = gesture.timestampMs;
      return null;
    }
    if (_secondTap == null && gesture.timestampMs - _firstTap! <= InputTuning.comboGapMs) {
      _secondTap = gesture.timestampMs;
      return OpeningEvent(OpeningAction.combo, BeatOffset(_firstTap! - beat));
    }
    return null;
  }

  @override
  OpeningEvent? finishOpening() {
    final double? beat = _openingBeat;
    final double? first = _firstTap;
    final bool combo = _secondTap != null;
    _openingBeat = null;
    _firstTap = null;
    _secondTap = null;
    if (beat == null || first == null) {
      return null;
    }
    return OpeningEvent(combo ? OpeningAction.combo : OpeningAction.strike, BeatOffset(first - beat));
  }
}
