import 'model_utils.dart';

/// The shape of a struggle's move. Each struggle's pattern is built from these.
enum MoveKind {
  /// A single normal hit.
  strike,

  /// Several quick hits.
  flurry,

  /// One slow, heavy hit.
  heavy,

  /// Small hits that add up.
  ping,

  /// A false telegraph: it looks like a move but does nothing.
  fake,

  /// An opening that is a trap.
  bait,

  /// A weak hit that mainly drains Stamina.
  drain,
}

/// One move a struggle can make.
class MoveDef {
  const MoveDef({
    required this.id,
    required this.kind,
    required this.telegraphMs,
    required this.damage,
    this.hits = 1,
    this.staminaDrain = 0,
  });

  final String id;
  final MoveKind kind;

  /// How long the tell shows before the move lands.
  final int telegraphMs;

  /// Resolve lost per hit when the move lands unanswered.
  final int damage;

  /// Number of hits in the move.
  final int hits;

  /// Extra Stamina the player loses when the move lands.
  final int staminaDrain;

  /// Whether this move can hurt the player at all.
  bool get isHarmless => kind == MoveKind.fake || damage == 0 && staminaDrain == 0;

  MoveDef copyWith({
    String? id,
    MoveKind? kind,
    int? telegraphMs,
    int? damage,
    int? hits,
    int? staminaDrain,
  }) {
    return MoveDef(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      telegraphMs: telegraphMs ?? this.telegraphMs,
      damage: damage ?? this.damage,
      hits: hits ?? this.hits,
      staminaDrain: staminaDrain ?? this.staminaDrain,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'kind': kind.name,
        'telegraphMs': telegraphMs,
        'damage': damage,
        'hits': hits,
        'staminaDrain': staminaDrain,
      };

  factory MoveDef.fromJson(Map<String, Object?> json) {
    return MoveDef(
      id: readString(json, 'id'),
      kind: readEnum(MoveKind.values, json, 'kind'),
      telegraphMs: readInt(json, 'telegraphMs'),
      damage: readInt(json, 'damage'),
      hits: readInt(json, 'hits'),
      staminaDrain: readInt(json, 'staminaDrain'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MoveDef &&
        other.id == id &&
        other.kind == kind &&
        other.telegraphMs == telegraphMs &&
        other.damage == damage &&
        other.hits == hits &&
        other.staminaDrain == staminaDrain;
  }

  @override
  int get hashCode => Object.hash(id, kind, telegraphMs, damage, hits, staminaDrain);

  @override
  String toString() => 'MoveDef($id, ${kind.name})';
}
