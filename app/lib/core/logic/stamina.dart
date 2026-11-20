import 'modifiers.dart';

/// What costs Stamina.
enum StaminaAction { guard, slip, strike, combo }

/// Stamina costs and regeneration (starting values).
abstract final class StaminaRules {
  static const int guardCost = 8;
  static const int slipCost = 6;
  static const int strikeCost = 10;
  static const int comboCost = 18;

  /// Stamina regained between exchanges during the telegraph.
  static const int regenPerExchange = 5;

  /// Extra Stamina for a perfect response.
  static const int perfectBonus = 4;

  /// Stamina gained by taking a move without answering it (bracing).
  static const int takeItGain = 4;

  /// Stamina a Breath recovers.
  static const int breathRecover = 30;

  /// Stamina refilled in the corner, as a percent of the maximum (Loneliness halves it).
  static const int cornerRefillPercent = 100;

  /// The Stamina cost of [action]. [costly] doubles it (Exhaustion).
  static int cost(StaminaAction action, Modifiers m, {bool costly = false}) {
    int base;
    switch (action) {
      case StaminaAction.guard:
        base = guardCost;
      case StaminaAction.slip:
        base = slipCost;
      case StaminaAction.strike:
        base = strikeCost;
      case StaminaAction.combo:
        base = comboCost + m.comboStaminaDelta;
    }
    if (base < 0) {
      base = 0;
    }
    return costly ? base * 2 : base;
  }

  /// Stamina regained per exchange after the stance and cards.
  static int regen(Modifiers m) {
    final int r = (regenPerExchange * (100 + m.staminaRegenPercent) / 100).round();
    return r < 0 ? 0 : r;
  }

  /// Keeps a Stamina value inside 0 to [max].
  static int clamp(int value, {int max = 100}) {
    if (value < 0) {
      return 0;
    }
    return value > max ? max : value;
  }
}
