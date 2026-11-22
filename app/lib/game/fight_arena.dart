import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'boxing_game.dart';
import 'fight_controller.dart';
import 'hud/fight_hud.dart';
import 'input/touch_layer.dart';

/// The whole fight view: the Flame scene, the touch layer and the HUD stacked.
/// The touch layer sits beneath the HUD so the HUD's buttons never count as
/// guard taps.
class FightArena extends StatelessWidget {
  const FightArena({super.key, required this.game, required this.controller, required this.labels, required this.locale, required this.onPause});

  final BoxingGame game;
  final FightController controller;
  final FightHudLabels labels;
  final String locale;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GameWidget<BoxingGame>(game: game),
        FightTouchLayer(onGesture: controller.gesture, nowMs: controller.nowMs, child: const SizedBox.expand()),
        FightHud(controller: controller, labels: labels, locale: locale, onPause: onPause),
      ],
    );
  }
}
