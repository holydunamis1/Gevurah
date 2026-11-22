import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/input/input_strategy.dart';
import '../core/models/beat_offset.dart';
import '../core/models/exchange_outcome.dart';
import '../core/models/exchange_record.dart';
import '../core/models/fight_state.dart';
import '../core/models/move_def.dart';
import '../core/ports/audio_port.dart';
import '../core/ports/haptics_port.dart';
import '../providers/fight_provider.dart';
import 'tuning.dart';

/// Something the scene and HUD react to.
sealed class FightEvent {
  const FightEvent();
}

/// A move's tell began; it lands in [telegraphMs].
class TelegraphStarted extends FightEvent {
  const TelegraphStarted(this.move, this.telegraphMs);

  final MoveDef move;
  final double telegraphMs;
}

/// The player answered. [opening] says an attack window now opens.
class ResponseRegistered extends FightEvent {
  const ResponseRegistered(this.response, this.quality, this.opening);

  final Response response;
  final Quality quality;
  final bool opening;
}

/// The attack window is open.
class OpeningOpened extends FightEvent {
  const OpeningOpened();
}

/// An exchange was decided.
class ExchangeResolved extends FightEvent {
  const ExchangeResolved(this.record);

  final ExchangeRecord record;
}

enum PauseReason { user, corner, tenCount, finished }

/// The controller stopped and waits: the screen shows a pause, the corner, the
/// ten-count or the result, then calls [FightController.resume] (not for the end).
class FightPaused extends FightEvent {
  const FightPaused(this.reason);

  final PauseReason reason;
}

class FightResumed extends FightEvent {
  const FightResumed();
}

enum ControllerPhase { idle, lead, waitingResponse, opening, settling, resolving, paused }

/// Connects the fight provider to the scene. It owns the one clock the bout
/// runs on (`nowMs`), turns input timestamps into beat offsets through the
/// input strategy, and hands the provider finished answers. Frame rate never
/// reaches the rules: a timestamp is compared with a beat, and frames only
/// decide when a phase ends. Call [tick] every frame.
class FightController {
  FightController({
    required this.fight,
    required this.input,
    required this.nowMs,
    this.haptics,
    this.audio,
  });

  final FightProvider fight;
  final InputStrategy input;

  /// A monotonic clock in milliseconds. Real play uses a Stopwatch; tests use a fake.
  final double Function() nowMs;
  final HapticsPort? haptics;
  final AudioPort? audio;

  final StreamController<FightEvent> _events = StreamController<FightEvent>.broadcast(sync: true);
  Stream<FightEvent> get events => _events.stream;

  /// The phase, as a notifier so the HUD can show or hide the tell when it changes.
  final ValueNotifier<ControllerPhase> phaseNotifier = ValueNotifier<ControllerPhase>(ControllerPhase.idle);

  /// The tell's progress each frame (0 outside a tell), for the HUD's countdown ring.
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);

  ControllerPhase get phase => phaseNotifier.value;
  ControllerPhase get _phase => phaseNotifier.value;
  set _phase(ControllerPhase p) => phaseNotifier.value = p;

  double _until = 0;
  double _telegraphStart = 0;
  double _beat = 0;
  double _telegraphMs = 0;
  double _openingBeat = 0;
  ResponseEvent? _response;
  OpeningEvent? _opening;
  bool _openingLost = false;
  bool _wasUserPause = false;

  /// 0 when a tell begins, 1 when it lands. The HUD reads this each frame.
  double get telegraphProgress {
    if (_phase != ControllerPhase.waitingResponse || _telegraphMs <= 0) {
      return 0;
    }
    return ((nowMs() - _telegraphStart) / _telegraphMs).clamp(0.0, 1.0);
  }

  /// The move being telegraphed, or null.
  MoveDef? get currentMove => fight.value?.move;

  void _emit(FightEvent e) {
    if (!_events.isClosed) {
      _events.add(e);
    }
  }

  void _haptic(HapticKind k) {
    final HapticsPort? h = haptics;
    if (h != null) {
      unawaited(h.play(k));
    }
  }

  void _sound(String id) {
    final AudioPort? a = audio;
    if (a != null) {
      unawaited(a.play(id));
    }
  }

  /// Starts the bout's first exchange after a short lead. Call after `fight.start`.
  void begin() {
    final AudioPort? a = audio;
    if (a != null) {
      unawaited(a.preload(GameTuning.allSounds));
    }
    _enterLead(GameTuning.resumeLeadMs);
  }

  void _enterLead(double ms) {
    _phase = ControllerPhase.lead;
    _until = nowMs() + ms;
  }

  /// Advances the phases by the clock. Safe to call every frame.
  void tick() {
    final double now = nowMs();
    final double p = telegraphProgress;
    if (progressNotifier.value != p) {
      progressNotifier.value = p;
    }
    switch (_phase) {
      case ControllerPhase.idle:
      case ControllerPhase.paused:
        return;
      case ControllerPhase.lead:
        if (now >= _until) {
          _startTelegraph(now);
        }
      case ControllerPhase.waitingResponse:
        if (now >= _beat + GameTuning.responseCloseMs) {
          _closeResponse(now);
        }
      case ControllerPhase.settling:
        if (now >= _beat) {
          _resolve(now);
        }
      case ControllerPhase.opening:
        if (now >= _openingBeat + GameTuning.openingCloseMs) {
          _closeOpening(now);
        }
      case ControllerPhase.resolving:
        if (now >= _until) {
          _afterResolved(now);
        }
    }
  }

  void _startTelegraph(double now) {
    final FightView? v = fight.value;
    final MoveDef? move = v?.move;
    final int? ms = fight.telegraphMs;
    if (v == null || move == null || ms == null || v.finished) {
      _pause(v != null && v.finished ? PauseReason.finished : PauseReason.corner);
      return;
    }
    _telegraphMs = ms.toDouble();
    _telegraphStart = now;
    _beat = now + _telegraphMs;
    _response = null;
    _opening = null;
    _openingLost = false;
    input.beginResponse(_beat);
    _phase = ControllerPhase.waitingResponse;
    _haptic(HapticKind.tellPulse);
    _sound(GameTuning.soundTell);
    _emit(TelegraphStarted(move, _telegraphMs));
  }

  /// Feed every touch here with its timestamp on the same clock as [nowMs].
  void gesture(RawGesture g) {
    switch (_phase) {
      case ControllerPhase.waitingResponse:
        final ResponseEvent? r = input.onResponseGesture(g);
        if (r != null) {
          _onResponse(r);
        }
      case ControllerPhase.opening:
        final OpeningEvent? o = input.onOpeningGesture(g);
        if (o != null) {
          _opening = o;
        }
      case ControllerPhase.idle:
      case ControllerPhase.lead:
      case ControllerPhase.settling:
      case ControllerPhase.resolving:
      case ControllerPhase.paused:
        return;
    }
  }

  void _onResponse(ResponseEvent r) {
    _response = r;
    final ExchangeOutcome? preview = fight.preview(response: r.response, offset: r.offset);
    final Quality q = preview?.quality ?? Quality.miss;
    final bool opens = (preview?.opening ?? false) && !_openingLost;
    _emit(ResponseRegistered(r.response, q, opens));
    _sound(r.response == Response.slip ? GameTuning.soundSlip : GameTuning.soundGuard);
    _haptic(q == Quality.perfect ? HapticKind.perfect : (q == Quality.miss ? HapticKind.error : HapticKind.selection));
    if (q == Quality.perfect) {
      _sound(GameTuning.soundPerfect);
    }
    // The input strategy has taken its answer; close the response now.
    input.finishResponse();
    final double now = nowMs();
    if (opens) {
      final double at = (now > _beat ? now : _beat);
      _openingBeat = at + GameTuning.openingDelayMs;
      input.beginOpening(_openingBeat);
      _phase = ControllerPhase.opening;
      _emit(const OpeningOpened());
    } else {
      _phase = ControllerPhase.settling;
    }
  }

  void _closeResponse(double now) {
    final ResponseEvent? r = input.finishResponse();
    _response ??= r;
    if (_response == null) {
      _resolve(now);
    } else {
      _phase = ControllerPhase.settling;
    }
  }

  void _closeOpening(double now) {
    _opening = input.finishOpening() ?? _opening;
    _resolve(now);
  }

  void _resolve(double now) {
    final ResponseEvent? r = _response;
    final OpeningEvent? o = _openingLost ? null : _opening;
    final ExchangeRecord? record = fight.respond(
      response: r?.response ?? Response.takeIt,
      offset: r?.offset ?? const BeatOffset(0),
      counter: o?.action ?? OpeningAction.none,
      strikeOffset: o?.strikeOffset,
    );
    _response = null;
    _opening = null;
    if (record == null) {
      _pause(PauseReason.finished);
      return;
    }
    if (record.outcome.damageTaken > 0) {
      _haptic(HapticKind.hit);
      _sound(GameTuning.soundHit);
    }
    _phase = ControllerPhase.resolving;
    _until = now + GameTuning.resolveShowMs;
    _emit(ExchangeResolved(record));
  }

  void _afterResolved(double now) {
    final FightView? v = fight.value;
    if (v == null) {
      _phase = ControllerPhase.idle;
      return;
    }
    if (v.finished) {
      _sound(v.won ? GameTuning.soundDefeat : GameTuning.soundDown);
      _pause(PauseReason.finished);
    } else if (v.state.phase == FightPhase.tenCount) {
      _sound(GameTuning.soundDown);
      _pause(PauseReason.tenCount);
    } else if (v.state.phase == FightPhase.corner) {
      _pause(PauseReason.corner);
    } else {
      _enterLead(GameTuning.interExchangeMs);
    }
  }

  void _pause(PauseReason reason) {
    _phase = ControllerPhase.paused;
    _wasUserPause = reason == PauseReason.user;
    _emit(FightPaused(reason));
  }

  /// A player pause. An exchange in progress is dropped without penalty and its
  /// tell restarts on [resume].
  void pause() {
    if (_phase == ControllerPhase.idle || _phase == ControllerPhase.paused) {
      return;
    }
    if (_phase == ControllerPhase.waitingResponse || _phase == ControllerPhase.opening || _phase == ControllerPhase.settling) {
      input.finishResponse();
      input.finishOpening();
      _response = null;
      _opening = null;
    }
    _pause(PauseReason.user);
  }

  /// Continues after a pause, the corner or the ten-count. Does nothing once the bout is over.
  void resume() {
    if (_phase != ControllerPhase.paused) {
      return;
    }
    final FightView? v = fight.value;
    if (v == null || v.finished) {
      return;
    }
    _wasUserPause = false;
    _emit(const FightResumed());
    _enterLead(GameTuning.resumeLeadMs);
  }

  bool get pausedByUser => _phase == ControllerPhase.paused && _wasUserPause;

  /// A Breath: Stamina back to full. Using it in an exchange costs that exchange's opening.
  void breathe() {
    final FightView? v = fight.value;
    if (v == null || v.finished || _phase == ControllerPhase.paused) {
      return;
    }
    if (v.state.player.breathCharges <= 0) {
      return;
    }
    fight.breathe();
    if (_phase == ControllerPhase.waitingResponse || _phase == ControllerPhase.settling) {
      _openingLost = true;
    } else if (_phase == ControllerPhase.opening) {
      _openingLost = true;
      input.finishOpening();
      _opening = null;
      _resolve(nowMs());
    }
  }

  /// A real clock for play: milliseconds since this call.
  static double Function() stopwatchClock() {
    final Stopwatch sw = Stopwatch()..start();
    return () => sw.elapsedMicroseconds / 1000.0;
  }

  Future<void> dispose() {
    phaseNotifier.dispose();
    progressNotifier.dispose();
    return _events.close();
  }
}
