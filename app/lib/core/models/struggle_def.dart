import 'model_utils.dart';
import 'move_def.dart';

/// Which part of the game a struggle belongs to.
enum StruggleTrack {
  /// The 16-opponent Journey, ending with Giving Up.
  career,

  /// The 10 extra struggles in the second track.
  trials,
}

/// What makes a struggle fight the way it does. The struggle AI reads these.
enum StruggleTrait {
  erratic,
  accumulating,
  charged,
  impatient,
  crowding,
  draining,
  costly,
  mirroring,
  deceptive,
  baiting,
  retreating,
  returning,
  countering,
  guardLow,
  resilient,
  blended,
  copying,
  late,
  decoys,
  repeating,
  splitting,
  escalating,
  perfectionist,
  swarming,
  grudging,
  chipping,
}

/// One struggle: an opponent defined entirely as data.
class StruggleDef {
  const StruggleDef({
    required this.id,
    required this.track,
    required this.tier,
    required this.weight,
    required this.traits,
    required this.moves,
    this.isFinal = false,
  });

  /// Stable slug, for example `fear`. Localization keys derive from it.
  final String id;
  final StruggleTrack track;

  /// 1 to 4. Higher tiers have shorter telegraphs and more Weight.
  final int tier;

  /// Starting Weight. The struggle is knocked down when it reaches zero.
  final int weight;
  final List<StruggleTrait> traits;
  final List<MoveDef> moves;

  /// True only for the final bout opponent.
  final bool isFinal;

  /// Localization key for the display name.
  String get nameKey => 'struggle_$id';

  /// Localization key for the one-line description of how it fights.
  String get tellKey => 'struggle_${id}_tell';

  bool hasTrait(StruggleTrait t) => traits.contains(t);

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'track': track.name,
        'tier': tier,
        'weight': weight,
        'traits': traits.map((StruggleTrait t) => t.name).toList(),
        'moves': moves.map((MoveDef m) => m.toJson()).toList(),
        'isFinal': isFinal,
      };

  factory StruggleDef.fromJson(Map<String, Object?> json) {
    final List<StruggleTrait> traits = <StruggleTrait>[];
    for (final Object? t in readList(json, 'traits')) {
      if (t is! String) {
        throw FormatException('Expected a trait name, got $t');
      }
      traits.add(StruggleTrait.values.byName(t));
    }
    final List<MoveDef> moves = <MoveDef>[];
    for (final Object? m in readList(json, 'moves')) {
      if (m is! Map<String, Object?>) {
        throw FormatException('Expected a move object, got $m');
      }
      moves.add(MoveDef.fromJson(m));
    }
    return StruggleDef(
      id: readString(json, 'id'),
      track: readEnum(StruggleTrack.values, json, 'track'),
      tier: readInt(json, 'tier'),
      weight: readInt(json, 'weight'),
      traits: traits,
      moves: moves,
      isFinal: readBool(json, 'isFinal'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StruggleDef &&
        other.id == id &&
        other.track == track &&
        other.tier == tier &&
        other.weight == weight &&
        other.isFinal == isFinal &&
        listEq(other.traits, traits) &&
        listEq(other.moves, moves);
  }

  @override
  int get hashCode => Object.hash(id, track, tier, weight, isFinal, listHash(traits), listHash(moves));

  @override
  String toString() => 'StruggleDef($id, tier $tier)';
}
