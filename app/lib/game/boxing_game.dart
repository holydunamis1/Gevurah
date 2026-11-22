import 'dart:ui';

import 'package:flame/game.dart';

import '../theme/tokens.dart';
import 'fight_controller.dart';
import 'fight_world.dart';

/// The Flame game for one bout. It drives the controller every frame and shows
/// the world. The HUD, the touch layer and every pause screen are ordinary
/// Flutter widgets above it.
class BoxingGame extends FlameGame {
  BoxingGame({required this.controller, required this.palette, required this.struggleId, this.reduceMotion = false});

  final FightController controller;
  final AppPalette palette;
  final String struggleId;
  final bool reduceMotion;

  late final FightWorld fightWorld = FightWorld(controller: controller, palette: palette, struggleId: struggleId, reduceMotion: reduceMotion);

  @override
  Color backgroundColor() => palette.bgPrimary;

  @override
  Future<void> onLoad() async {
    await add(fightWorld);
  }

  @override
  void update(double dt) {
    controller.tick();
    super.update(dt);
  }
}
