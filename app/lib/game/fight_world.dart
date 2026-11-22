import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/models/exchange_outcome.dart';
import '../core/models/exchange_record.dart';
import '../core/models/fight_state.dart';
import '../providers/fight_provider.dart';
import '../theme/tokens.dart';
import 'components/effects.dart';
import 'components/fighter.dart';
import 'components/ring.dart';
import 'components/shadow.dart';
import 'fight_controller.dart';
import 'tuning.dart';

/// The scene: ring, fighter and shadow, reacting to the controller's events.
/// It only draws and animates; it never decides an outcome.
class FightWorld extends PositionComponent {
  FightWorld({required this.controller, required this.palette, required String struggleId, this.reduceMotion = false})
      : shadow = Shadow(shape: ShadowShape.forId(struggleId), palette: palette, reduceMotion: reduceMotion),
        fighter = Fighter(palette: palette, reduceMotion: reduceMotion),
        ring = Ring(palette: palette);

  final FightController controller;
  final AppPalette palette;
  final bool reduceMotion;
  final Ring ring;
  final Fighter fighter;
  final Shadow shadow;

  StreamSubscription<FightEvent>? _sub;
  final List<_Timer> _timers = <_Timer>[];
  int _lastRises = 0;

  FightProvider get _fight => controller.fight;

  @override
  Future<void> onLoad() async {
    await addAll(<Component>[ring, shadow, fighter]);
    _layout();
  }

  @override
  void onMount() {
    super.onMount();
    _sub = controller.events.listen(_onEvent);
  }

  @override
  void onRemove() {
    unawaited(_sub?.cancel());
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _layout();
  }

  void _layout() {
    ring.size = size;
    final double figH = size.y * GameTuning.figureHeight;
    final double floor = size.y * GameTuning.floorY;
    fighter
      ..size = Vector2(figH * 0.9, figH)
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x * GameTuning.playerX, floor);
    shadow
      ..size = Vector2(size.x * 0.42, figH * 1.5)
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x * GameTuning.shadowX, floor + figH * 0.1);
  }

  void _later(double ms, void Function() action) => _timers.add(_Timer(ms, action));

  void _spawn(EffectKind kind, Vector2 at, Color color, {double radius = 60}) {
    add(Effect(kind: kind, color: color, reduceMotion: reduceMotion, radius: radius)..position = at);
  }

  Vector2 get _shadowCenter => shadow.position + Vector2(0, -shadow.size.y * 0.5);
  Vector2 get _fighterChest => fighter.position + Vector2(0, -fighter.size.y * 0.55);

  void _onEvent(FightEvent e) {
    switch (e) {
      case TelegraphStarted():
        shadow.tell(0);
      case ResponseRegistered(:final Response response, :final Quality quality):
        if (response == Response.guard) {
          fighter.show(FighterPose.guard);
        } else if (response == Response.slip) {
          fighter.show(FighterPose.slip);
        }
        if (quality == Quality.perfect) {
          _spawn(EffectKind.perfect, _fighterChest, palette.success, radius: fighter.size.y * 0.5);
        }
      case OpeningOpened():
        {}
      case ExchangeResolved(:final ExchangeRecord record):
        _onResolved(record);
      case FightPaused():
        {}
      case FightResumed():
        fighter.show(FighterPose.idle);
        if (shadow.state == ShadowState.tell) {
          shadow.settle();
        }
    }
  }

  void _onResolved(ExchangeRecord r) {
    final FightView? v = _fight.value;
    shadow.lunge();
    if (r.outcome.damageTaken > 0) {
      _spawn(EffectKind.impact, _fighterChest, palette.error, radius: fighter.size.y * 0.45);
    }
    if (r.counter != OpeningAction.none && r.outcome.damageDealt > 0) {
      fighter.show(r.counter == OpeningAction.combo ? FighterPose.combo : FighterPose.jab);
      _later(GameTuning.lungeMs, () {
        shadow.flinch();
        _spawn(EffectKind.impact, _shadowCenter, palette.accent, radius: shadow.size.y * 0.3);
      });
    }
    if (v == null) {
      return;
    }
    if (v.state.struggleRises > _lastRises) {
      _lastRises = v.state.struggleRises;
      _later(GameTuning.lungeMs + 100, () {
        shadow.knockDown();
        _spawn(EffectKind.stars, _shadowCenter, palette.warning, radius: shadow.size.y * 0.3);
      });
      _later(GameTuning.lungeMs + 100 + GameTuning.defeatLiftMs, shadow.rise);
    }
    if (v.state.phase == FightPhase.tenCount || (v.finished && !v.won)) {
      fighter.show(FighterPose.stagger);
    }
    if (v.finished && v.won) {
      _later(GameTuning.lungeMs + 100, () {
        shadow.knockDown();
        _spawn(EffectKind.stars, _shadowCenter, palette.warning, radius: shadow.size.y * 0.3);
      });
      _later(GameTuning.lungeMs + 100 + GameTuning.starsMs * 0.6, shadow.dissolve);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (controller.phase == ControllerPhase.waitingResponse) {
      shadow.tell(controller.telegraphProgress);
    }
    final double ms = dt * 1000;
    for (final _Timer t in List<_Timer>.of(_timers)) {
      t.left -= ms;
      if (t.left <= 0) {
        _timers.remove(t);
        t.action();
      }
    }
  }
}

class _Timer {
  _Timer(this.left, this.action);

  double left;
  final void Function() action;
}
