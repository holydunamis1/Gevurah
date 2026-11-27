import '../models/beat_offset.dart';
import '../models/exchange_record.dart';
import 'input_strategy.dart';

/// The one-tap game: any touch, tap or swipe, blocks. There is no Slip and no
/// Combo to learn; the counter is thrown by the game when a block earns one.
class OneTapStrategy implements InputStrategy {
  double? _beat;
  ResponseEvent? _response;

  /// Touches further than this from the beat are too far to be an attempt.
  static const double attemptRangeMs = 450;

  @override
  void beginResponse(double beatMs) {
    _beat = beatMs;
    _response = null;
  }

  @override
  void beginOpening(double beatMs) {}

  @override
  ResponseEvent? onResponseGesture(RawGesture gesture) {
    final double? beat = _beat;
    if (beat == null || _response != null) {
      return null;
    }
    final double offset = gesture.timestampMs - beat;
    if (offset.abs() > attemptRangeMs) {
      return null;
    }
    return _response = ResponseEvent(Response.guard, BeatOffset(offset));
  }

  @override
  ResponseEvent? finishResponse() {
    final ResponseEvent? r = _response;
    _beat = null;
    _response = null;
    return r;
  }

  @override
  OpeningEvent? onOpeningGesture(RawGesture gesture) => null;

  @override
  OpeningEvent? finishOpening() => null;
}
