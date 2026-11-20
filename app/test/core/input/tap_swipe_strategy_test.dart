import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/input/input_strategy.dart';
import 'package:gevurah/core/input/tap_swipe_strategy.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_record.dart';

void main() {
  group('responses', () {
    test('a tap on the beat is a perfect guard', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.tap(1000)), const ResponseEvent(Response.guard, BeatOffset(0)));
    });

    test('early and late taps carry a signed offset', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.tap(930))!.offset.ms, -70);
      s.beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.tap(1110))!.offset.ms, 110);
    });

    test('a sideways flick is a slip', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      final ResponseEvent? e = s.onResponseGesture(const RawGesture.swipe(1020, dx: -90, dy: 10));
      expect(e!.response, Response.slip);
      expect(e.offset.ms, 20);
    });

    test('a very short swipe counts as a tap', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.swipe(1000, dx: 8, dy: 3))!.response, Response.guard);
    });

    test('a mostly vertical or slow drag is ignored', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.swipe(1000, dx: 40, dy: 80)), isNull);
      expect(s.onResponseGesture(const RawGesture.swipe(1000, dx: 120, durationMs: 900)), isNull);
    });

    test('a gesture far from the beat is not an attempt', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      expect(s.onResponseGesture(const RawGesture.tap(300)), isNull);
      expect(s.onResponseGesture(const RawGesture.tap(1600)), isNull);
    });

    test('only the first gesture counts (double taps)', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      s.onResponseGesture(const RawGesture.tap(990));
      expect(s.onResponseGesture(const RawGesture.tap(1005)), isNull);
      expect(s.finishResponse()!.offset.ms, -10);
    });

    test('no gesture means Take it (null) and the window resets', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginResponse(1000);
      expect(s.finishResponse(), isNull);
      expect(s.onResponseGesture(const RawGesture.tap(1000)), isNull, reason: 'no window open');
    });
  });

  group('openings', () {
    test('one tap is a strike with its own offset', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginOpening(2000);
      expect(s.onOpeningGesture(const RawGesture.tap(2040)), isNull);
      expect(s.finishOpening(), const OpeningEvent(OpeningAction.strike, BeatOffset(40)));
    });

    test('two quick taps are a combo, reported at the second tap', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginOpening(2000);
      s.onOpeningGesture(const RawGesture.tap(1990));
      final OpeningEvent? e = s.onOpeningGesture(const RawGesture.tap(2150));
      expect(e, const OpeningEvent(OpeningAction.combo, BeatOffset(-10)));
      expect(s.onOpeningGesture(const RawGesture.tap(2200)), isNull);
      expect(s.finishOpening(), const OpeningEvent(OpeningAction.combo, BeatOffset(-10)));
    });

    test('two slow taps stay a strike', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginOpening(2000);
      s.onOpeningGesture(const RawGesture.tap(1900));
      expect(s.onOpeningGesture(const RawGesture.tap(2300)), isNull);
      expect(s.finishOpening()!.action, OpeningAction.strike);
    });

    test('no taps means nothing was thrown; swipes do not strike', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginOpening(2000);
      expect(s.onOpeningGesture(const RawGesture.swipe(2000, dx: 100)), isNull);
      expect(s.finishOpening(), isNull);
      expect(s.finishOpening(), isNull);
    });

    test('a tap far from the beat does not open an attack', () {
      final TapSwipeStrategy s = TapSwipeStrategy()..beginOpening(2000);
      expect(s.onOpeningGesture(const RawGesture.tap(1000)), isNull);
      expect(s.finishOpening(), isNull);
    });
  });

  test('events have equality and readable text', () {
    expect(const ResponseEvent(Response.slip, BeatOffset(5)), const ResponseEvent(Response.slip, BeatOffset(5)));
    expect(const ResponseEvent(Response.slip, BeatOffset(5)).hashCode, const ResponseEvent(Response.slip, BeatOffset(5)).hashCode);
    expect(const OpeningEvent(OpeningAction.strike, BeatOffset(5)).toString(), contains('strike'));
    expect(const ResponseEvent(Response.guard, BeatOffset(5)).toString(), contains('guard'));
  });
}
