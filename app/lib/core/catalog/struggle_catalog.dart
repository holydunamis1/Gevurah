import '../models/move_def.dart';
import '../models/struggle_def.dart';

/// Starting Weight by tier. Tuning starting values: the seeded balance
/// simulation adjusts them.
const Map<int, int> _weightByTier = <int, int>{1: 60, 2: 80, 3: 100, 4: 120};

/// Weight of the final bout opponent.
const int _finalWeight = 160;

MoveDef _move(
  String id,
  MoveKind kind, {
  required int telegraphMs,
  required int damage,
  int hits = 1,
  int staminaDrain = 0,
}) {
  return MoveDef(
    id: id,
    kind: kind,
    telegraphMs: telegraphMs,
    damage: damage,
    hits: hits,
    staminaDrain: staminaDrain,
  );
}

StruggleDef _struggle(
  String id,
  StruggleTrack track,
  int tier,
  List<StruggleTrait> traits,
  List<MoveDef> moves, {
  bool isFinal = false,
}) {
  return StruggleDef(
    id: id,
    track: track,
    tier: tier,
    weight: isFinal ? _finalWeight : _weightByTier[tier]!,
    traits: traits,
    moves: moves,
    isFinal: isFinal,
  );
}

/// The 26 struggles. Each is data; how a trait plays out is the struggle AI's job.
abstract final class StruggleCatalog {
  static final List<StruggleDef> career = List<StruggleDef>.unmodifiable(<StruggleDef>[
    // Tier 1
    _struggle('fear', StruggleTrack.career, 1, <StruggleTrait>[StruggleTrait.erratic], <MoveDef>[
      _move('fear_flurry', MoveKind.flurry, telegraphMs: 630, damage: 3, hits: 3),
      _move('fear_strike', MoveKind.strike, telegraphMs: 900, damage: 6),
    ]),
    _struggle('worry', StruggleTrack.career, 1, <StruggleTrait>[StruggleTrait.accumulating], <MoveDef>[
      _move('worry_ping_a', MoveKind.ping, telegraphMs: 800, damage: 2, hits: 4),
      _move('worry_ping_b', MoveKind.ping, telegraphMs: 900, damage: 1, hits: 6),
    ]),
    _struggle('anger', StruggleTrack.career, 1, <StruggleTrait>[StruggleTrait.charged], <MoveDef>[
      _move('anger_heavy', MoveKind.heavy, telegraphMs: 1100, damage: 14),
      _move('anger_strike', MoveKind.strike, telegraphMs: 900, damage: 6),
    ]),
    _struggle('impatience', StruggleTrack.career, 1, <StruggleTrait>[StruggleTrait.impatient], <MoveDef>[
      _move('impatience_strike_a', MoveKind.strike, telegraphMs: 540, damage: 6),
      _move('impatience_strike_b', MoveKind.strike, telegraphMs: 480, damage: 5),
    ]),
    // Tier 2
    _struggle('loneliness', StruggleTrack.career, 2, <StruggleTrait>[StruggleTrait.crowding], <MoveDef>[
      _move('loneliness_strike', MoveKind.strike, telegraphMs: 750, damage: 8),
      _move('loneliness_flurry', MoveKind.flurry, telegraphMs: 650, damage: 4, hits: 2),
    ]),
    _struggle('discouragement', StruggleTrack.career, 2, <StruggleTrait>[StruggleTrait.draining], <MoveDef>[
      _move('discouragement_drain_a', MoveKind.drain, telegraphMs: 750, damage: 4, staminaDrain: 12),
      _move('discouragement_drain_b', MoveKind.drain, telegraphMs: 700, damage: 3, staminaDrain: 15),
    ]),
    _struggle('exhaustion', StruggleTrack.career, 2, <StruggleTrait>[StruggleTrait.costly], <MoveDef>[
      _move('exhaustion_strike', MoveKind.strike, telegraphMs: 750, damage: 8),
      _move('exhaustion_heavy', MoveKind.heavy, telegraphMs: 900, damage: 12),
    ]),
    _struggle('envy', StruggleTrack.career, 2, <StruggleTrait>[StruggleTrait.mirroring], <MoveDef>[
      _move('envy_strike_a', MoveKind.strike, telegraphMs: 750, damage: 8),
      _move('envy_strike_b', MoveKind.strike, telegraphMs: 700, damage: 10),
    ]),
    // Tier 3
    _struggle('doubt', StruggleTrack.career, 3, <StruggleTrait>[StruggleTrait.deceptive], <MoveDef>[
      _move('doubt_strike', MoveKind.strike, telegraphMs: 600, damage: 10),
      _move('doubt_fake_a', MoveKind.fake, telegraphMs: 600, damage: 0),
      _move('doubt_fake_b', MoveKind.fake, telegraphMs: 500, damage: 0),
      _move('doubt_heavy', MoveKind.heavy, telegraphMs: 700, damage: 14),
    ]),
    _struggle('temptation', StruggleTrack.career, 3, <StruggleTrait>[StruggleTrait.baiting], <MoveDef>[
      _move('temptation_bait', MoveKind.bait, telegraphMs: 600, damage: 12),
      _move('temptation_strike', MoveKind.strike, telegraphMs: 600, damage: 10),
    ]),
    _struggle('rejection', StruggleTrack.career, 3, <StruggleTrait>[StruggleTrait.retreating], <MoveDef>[
      _move('rejection_strike', MoveKind.strike, telegraphMs: 600, damage: 10),
      _move('rejection_flurry', MoveKind.flurry, telegraphMs: 520, damage: 5, hits: 2),
    ]),
    _struggle('bitterness', StruggleTrack.career, 3, <StruggleTrait>[StruggleTrait.returning], <MoveDef>[
      _move('bitterness_strike', MoveKind.strike, telegraphMs: 600, damage: 10),
      _move('bitterness_heavy', MoveKind.heavy, telegraphMs: 700, damage: 13),
    ]),
    // Tier 4
    _struggle('pride', StruggleTrack.career, 4, <StruggleTrait>[StruggleTrait.countering], <MoveDef>[
      _move('pride_strike', MoveKind.strike, telegraphMs: 450, damage: 12),
      _move('pride_heavy', MoveKind.heavy, telegraphMs: 550, damage: 16),
    ]),
    _struggle('shame', StruggleTrack.career, 4, <StruggleTrait>[StruggleTrait.guardLow], <MoveDef>[
      _move('shame_flurry', MoveKind.flurry, telegraphMs: 450, damage: 5, hits: 3),
      _move('shame_strike', MoveKind.strike, telegraphMs: 450, damage: 12),
    ]),
    _struggle('failure', StruggleTrack.career, 4, <StruggleTrait>[StruggleTrait.resilient], <MoveDef>[
      _move('failure_strike', MoveKind.strike, telegraphMs: 450, damage: 12),
      _move('failure_heavy', MoveKind.heavy, telegraphMs: 520, damage: 15),
    ]),
    // The final bout: Still Standing, against Giving Up.
    _struggle(
      'giving_up',
      StruggleTrack.career,
      4,
      <StruggleTrait>[StruggleTrait.blended, StruggleTrait.erratic, StruggleTrait.deceptive, StruggleTrait.draining, StruggleTrait.baiting],
      <MoveDef>[
        _move('giving_up_flurry', MoveKind.flurry, telegraphMs: 420, damage: 5, hits: 3),
        _move('giving_up_heavy', MoveKind.heavy, telegraphMs: 520, damage: 18),
        _move('giving_up_fake', MoveKind.fake, telegraphMs: 450, damage: 0),
        _move('giving_up_drain', MoveKind.drain, telegraphMs: 450, damage: 5, staminaDrain: 15),
        _move('giving_up_bait', MoveKind.bait, telegraphMs: 450, damage: 14),
      ],
      isFinal: true,
    ),
  ]);

  static final List<StruggleDef> trials = List<StruggleDef>.unmodifiable(<StruggleDef>[
    _struggle('complaining', StruggleTrack.trials, 1, <StruggleTrait>[StruggleTrait.chipping], <MoveDef>[
      _move('complaining_ping', MoveKind.ping, telegraphMs: 850, damage: 1, hits: 5),
      _move('complaining_strike', MoveKind.strike, telegraphMs: 900, damage: 6),
    ]),
    _struggle('procrastination', StruggleTrack.trials, 2, <StruggleTrait>[StruggleTrait.late], <MoveDef>[
      _move('procrastination_strike', MoveKind.strike, telegraphMs: 1000, damage: 8),
      _move('procrastination_heavy', MoveKind.heavy, telegraphMs: 1000, damage: 11),
    ]),
    _struggle('distraction', StruggleTrack.trials, 2, <StruggleTrait>[StruggleTrait.decoys], <MoveDef>[
      _move('distraction_fake', MoveKind.fake, telegraphMs: 700, damage: 0),
      _move('distraction_strike', MoveKind.strike, telegraphMs: 750, damage: 8),
    ]),
    _struggle('money_pressure', StruggleTrack.trials, 2, <StruggleTrait>[StruggleTrait.escalating], <MoveDef>[
      _move('money_pressure_drain', MoveKind.drain, telegraphMs: 750, damage: 5, staminaDrain: 10),
      _move('money_pressure_strike', MoveKind.strike, telegraphMs: 750, damage: 8),
    ]),
    _struggle('comparison', StruggleTrack.trials, 3, <StruggleTrait>[StruggleTrait.copying], <MoveDef>[
      _move('comparison_strike_a', MoveKind.strike, telegraphMs: 600, damage: 10),
      _move('comparison_strike_b', MoveKind.strike, telegraphMs: 560, damage: 11),
    ]),
    _struggle('regret', StruggleTrack.trials, 3, <StruggleTrait>[StruggleTrait.repeating], <MoveDef>[
      _move('regret_strike', MoveKind.strike, telegraphMs: 600, damage: 10),
      _move('regret_heavy', MoveKind.heavy, telegraphMs: 650, damage: 13),
    ]),
    _struggle('indecision', StruggleTrack.trials, 3, <StruggleTrait>[StruggleTrait.splitting], <MoveDef>[
      _move('indecision_strike_a', MoveKind.strike, telegraphMs: 600, damage: 10),
      _move('indecision_strike_b', MoveKind.strike, telegraphMs: 600, damage: 9),
    ]),
    _struggle('overwhelm', StruggleTrack.trials, 3, <StruggleTrait>[StruggleTrait.swarming], <MoveDef>[
      _move('overwhelm_ping', MoveKind.ping, telegraphMs: 600, damage: 1, hits: 6),
      _move('overwhelm_flurry', MoveKind.flurry, telegraphMs: 560, damage: 3, hits: 3),
    ]),
    _struggle('perfectionism', StruggleTrack.trials, 4, <StruggleTrait>[StruggleTrait.perfectionist], <MoveDef>[
      _move('perfectionism_strike', MoveKind.strike, telegraphMs: 450, damage: 12),
      _move('perfectionism_flurry', MoveKind.flurry, telegraphMs: 450, damage: 4, hits: 3),
    ]),
    _struggle('unforgiveness', StruggleTrack.trials, 4, <StruggleTrait>[StruggleTrait.grudging], <MoveDef>[
      _move('unforgiveness_heavy', MoveKind.heavy, telegraphMs: 520, damage: 16),
      _move('unforgiveness_strike', MoveKind.strike, telegraphMs: 450, damage: 12),
    ]),
  ]);

  /// All 26 struggles: career first, then trials.
  static final List<StruggleDef> all = List<StruggleDef>.unmodifiable(<StruggleDef>[...career, ...trials]);

  static final Map<String, StruggleDef> _byId = <String, StruggleDef>{
    for (final StruggleDef s in all) s.id: s,
  };

  /// The struggle with [id], or null.
  static StruggleDef? byId(String id) => _byId[id];

  /// The final bout opponent, Giving Up.
  static StruggleDef get finalBout => career.firstWhere((StruggleDef s) => s.isFinal);

  /// The career struggles of one tier, in order.
  static List<StruggleDef> careerTier(int tier) =>
      career.where((StruggleDef s) => s.tier == tier).toList(growable: false);
}
