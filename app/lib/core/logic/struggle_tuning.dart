import '../models/struggle_def.dart';

/// Balance numbers per struggle, set by the balance simulation. Kept apart
/// from the catalog so tuning never edits the move sets.
abstract final class StruggleTuning {
  /// Percent of a move's damage that reaches the player, by tier.
  static const Map<int, int> tierDamagePercent = <int, int>{1: 220, 2: 150, 3: 130, 4: 80};

  /// Per-struggle replacements for the tier value.
  static const Map<String, int> damagePercentOverrides = <String, int>{
    'temptation': 100,
    'exhaustion': 100,
    'shame': 50,
    'failure': 50,
    'pride': 80,
    'giving_up': 70,
    'perfectionism': 80,
    'unforgiveness': 65,
  };

  static int incomingDamagePercent(StruggleDef def) {
    return damagePercentOverrides[def.id] ?? tierDamagePercent[def.tier] ?? 100;
  }
}
