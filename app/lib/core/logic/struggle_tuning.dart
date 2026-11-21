import '../models/struggle_def.dart';

/// Balance numbers per struggle, set by the balance simulation. Kept apart
/// from the catalog so tuning never edits the move sets.
abstract final class StruggleTuning {
  /// Percent of a move's damage that reaches the player, by tier.
  static const Map<int, int> tierDamagePercent = <int, int>{1: 300, 2: 250, 3: 200, 4: 100};

  /// Per-struggle replacements for the tier value.
  static const Map<String, int> damagePercentOverrides = <String, int>{
    'temptation': 130,
    'exhaustion': 90,
    'shame': 70,
    'failure': 75,
    'pride': 100,
    'giving_up': 110,
    'perfectionism': 100,
    'unforgiveness': 80,
  };

  static int incomingDamagePercent(StruggleDef def) {
    return damagePercentOverrides[def.id] ?? tierDamagePercent[def.tier] ?? 100;
  }
}
