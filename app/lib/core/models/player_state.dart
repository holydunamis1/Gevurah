import 'model_utils.dart';

/// The player's state during a bout.
class PlayerState {
  const PlayerState({
    required this.resolve,
    required this.stamina,
    required this.downs,
    required this.breathCharges,
    this.staminaCap = maxStamina,
  });

  static const int maxResolve = 100;
  static const int maxStamina = 100;
  static const int breathPerRound = 1;

  /// The state at the start of a bout.
  const PlayerState.initial()
      : resolve = maxResolve,
        stamina = maxStamina,
        downs = 0,
        breathCharges = breathPerRound,
        staminaCap = maxStamina;

  /// The state at the start of a bout with a reward applied: [extraBreath]
  /// more Breath charges and [extraStamina] more Stamina, which also raises the
  /// Stamina cap for the whole bout.
  const PlayerState.boosted({int extraBreath = 0, int extraStamina = 0})
      : resolve = maxResolve,
        stamina = maxStamina + extraStamina,
        downs = 0,
        breathCharges = breathPerRound + extraBreath,
        staminaCap = maxStamina + extraStamina;

  final int resolve;
  final int stamina;

  /// Times the player has been down in this bout; three ends it.
  final int downs;

  /// Breath uses left this round.
  final int breathCharges;

  /// The most Stamina the player can hold in this bout (100 unless a reward raised it).
  final int staminaCap;

  bool get isDown => resolve <= 0;

  PlayerState copyWith({int? resolve, int? stamina, int? downs, int? breathCharges, int? staminaCap}) {
    return PlayerState(
      resolve: resolve ?? this.resolve,
      stamina: stamina ?? this.stamina,
      downs: downs ?? this.downs,
      breathCharges: breathCharges ?? this.breathCharges,
      staminaCap: staminaCap ?? this.staminaCap,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'resolve': resolve,
        'stamina': stamina,
        'downs': downs,
        'breathCharges': breathCharges,
        if (staminaCap != maxStamina) 'staminaCap': staminaCap,
      };

  factory PlayerState.fromJson(Map<String, Object?> json) {
    return PlayerState(
      resolve: readInt(json, 'resolve'),
      stamina: readInt(json, 'stamina'),
      downs: readInt(json, 'downs'),
      breathCharges: readInt(json, 'breathCharges'),
      staminaCap: json['staminaCap'] is int ? json['staminaCap']! as int : maxStamina,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerState &&
        other.resolve == resolve &&
        other.stamina == stamina &&
        other.downs == downs &&
        other.breathCharges == breathCharges &&
        other.staminaCap == staminaCap;
  }

  @override
  int get hashCode => Object.hash(resolve, stamina, downs, breathCharges, staminaCap);

  @override
  String toString() => 'PlayerState(resolve $resolve, stamina $stamina, downs $downs, breath $breathCharges)';
}
