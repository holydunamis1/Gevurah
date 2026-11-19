import 'model_utils.dart';

/// The player's state during a bout.
class PlayerState {
  const PlayerState({
    required this.resolve,
    required this.stamina,
    required this.downs,
    required this.breathCharges,
  });

  static const int maxResolve = 100;
  static const int maxStamina = 100;
  static const int breathPerRound = 1;

  /// The state at the start of a bout.
  const PlayerState.initial()
      : resolve = maxResolve,
        stamina = maxStamina,
        downs = 0,
        breathCharges = breathPerRound;

  final int resolve;
  final int stamina;

  /// Times the player has been down in this bout; three ends it.
  final int downs;

  /// Breath uses left this round.
  final int breathCharges;

  bool get isDown => resolve <= 0;

  PlayerState copyWith({int? resolve, int? stamina, int? downs, int? breathCharges}) {
    return PlayerState(
      resolve: resolve ?? this.resolve,
      stamina: stamina ?? this.stamina,
      downs: downs ?? this.downs,
      breathCharges: breathCharges ?? this.breathCharges,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'resolve': resolve,
        'stamina': stamina,
        'downs': downs,
        'breathCharges': breathCharges,
      };

  factory PlayerState.fromJson(Map<String, Object?> json) {
    return PlayerState(
      resolve: readInt(json, 'resolve'),
      stamina: readInt(json, 'stamina'),
      downs: readInt(json, 'downs'),
      breathCharges: readInt(json, 'breathCharges'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerState &&
        other.resolve == resolve &&
        other.stamina == stamina &&
        other.downs == downs &&
        other.breathCharges == breathCharges;
  }

  @override
  int get hashCode => Object.hash(resolve, stamina, downs, breathCharges);

  @override
  String toString() => 'PlayerState(resolve $resolve, stamina $stamina, downs $downs, breath $breathCharges)';
}
