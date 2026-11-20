import '../models/beat_offset.dart';
import '../models/exchange_record.dart';

/// A raw touch gesture the game layer timestamps. The core never sees frame
/// time: [timestampMs] is the time the gesture was recognised, in the same
/// clock as the beat times the caller passes to the strategy.
class RawGesture {
  const RawGesture.tap(this.timestampMs)
      : dx = 0,
        dy = 0,
        durationMs = 0;

  const RawGesture.swipe(this.timestampMs, {required this.dx, this.dy = 0, this.durationMs = 120});

  final double timestampMs;

  /// Horizontal and vertical travel in logical pixels (zero for a tap).
  final double dx;
  final double dy;
  final double durationMs;
}

/// An answer to a telegraph: Guard or Slip, with its offset from the beat.
class ResponseEvent {
  const ResponseEvent(this.response, this.offset);

  final Response response;
  final BeatOffset offset;

  @override
  bool operator ==(Object other) =>
      other is ResponseEvent && other.response == response && other.offset == offset;

  @override
  int get hashCode => Object.hash(response, offset);

  @override
  String toString() => 'ResponseEvent(${response.name}, ${offset.ms} ms)';
}

/// An attack in the opening: Strike or Combo, with the first tap's offset.
class OpeningEvent {
  const OpeningEvent(this.action, this.strikeOffset);

  final OpeningAction action;
  final BeatOffset strikeOffset;

  @override
  bool operator ==(Object other) =>
      other is OpeningEvent && other.action == action && other.strikeOffset == strikeOffset;

  @override
  int get hashCode => Object.hash(action, strikeOffset);

  @override
  String toString() => 'OpeningEvent(${action.name}, ${strikeOffset.ms} ms)';
}

/// Turns raw gestures into rule inputs. The game layer feeds gestures and the
/// beat times; the strategy answers with events and never touches frame time.
abstract class InputStrategy {
  /// Starts waiting for a response to a move landing at [beatMs].
  void beginResponse(double beatMs);

  /// Starts waiting for an attack in an opening centred on [beatMs].
  void beginOpening(double beatMs);

  /// Feeds one gesture. Returns a response event when one is complete, else null.
  ResponseEvent? onResponseGesture(RawGesture gesture);

  /// Feeds one gesture during an opening. Returns the attack once it is
  /// settled, else null; call [finishOpening] when the opening window ends.
  OpeningEvent? onOpeningGesture(RawGesture gesture);

  /// Ends the opening and returns what was thrown, or null if nothing.
  OpeningEvent? finishOpening();

  /// Ends the response window. Null means the player did nothing: Take it.
  ResponseEvent? finishResponse();
}
