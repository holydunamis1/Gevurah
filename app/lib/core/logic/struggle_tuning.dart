import '../models/struggle_def.dart';

/// Balance numbers per struggle, set by the balance simulation. Kept apart
/// from the catalog so tuning never edits the move sets.
abstract final class StruggleTuning {
  /// Percent of a move's damage that reaches the player, by tier.
  static const Map<int, int> tierDamagePercent = <int, int>{1: 600, 2: 450, 3: 330, 4: 160};

  /// Per-struggle replacements for the tier value.
  static const Map<String, int> damagePercentOverrides = <String, int>{
    'temptation': 200,
    'exhaustion': 140,
    'bitterness': 200,
    'comparison': 260,
    'regret': 260,
    'overwhelm': 260,
    'shame': 160,
    'failure': 160,
    'pride': 170,
    'giving_up': 260,
    'perfectionism': 180,
    'unforgiveness': 160,
  };

  static int incomingDamagePercent(StruggleDef def) {
    return damagePercentOverrides[def.id] ?? tierDamagePercent[def.tier] ?? 100;
  }
}
