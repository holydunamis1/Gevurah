import '../models/struggle_def.dart';

/// Balance numbers per struggle, set by the balance simulation. Kept apart
/// from the catalog so tuning never edits the move sets.
abstract final class StruggleTuning {
  /// Percent of a move's damage that reaches the player, by tier.
  static const Map<int, int> tierDamagePercent = <int, int>{1: 400, 2: 330, 3: 260, 4: 100};

  /// Per-struggle replacements for the tier value.
  static const Map<String, int> damagePercentOverrides = <String, int>{
    'temptation': 160,
    'exhaustion': 110,
    'bitterness': 160,
    'comparison': 200,
    'regret': 200,
    'overwhelm': 200,
    'shame': 100,
    'failure': 90,
    'pride': 100,
    'giving_up': 110,
    'perfectionism': 120,
    'unforgiveness': 110,
  };

  static int incomingDamagePercent(StruggleDef def) {
    return damagePercentOverrides[def.id] ?? tierDamagePercent[def.tier] ?? 100;
  }
}
