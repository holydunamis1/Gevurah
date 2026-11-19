import 'model_utils.dart';

/// How well the player's response matched the beat.
enum Quality { perfect, good, miss }

/// The result of one exchange, decided by the exchange resolver.
class ExchangeOutcome {
  const ExchangeOutcome({
    required this.quality,
    required this.damageTaken,
    required this.damageDealt,
    required this.staminaChange,
    required this.opening,
  });

  final Quality quality;

  /// Resolve the player loses.
  final int damageTaken;

  /// Weight removed from the struggle.
  final int damageDealt;

  /// Signed change to the player's Stamina (negative is a cost).
  final int staminaChange;

  /// Whether the response earned an attack window.
  final bool opening;

  ExchangeOutcome copyWith({
    Quality? quality,
    int? damageTaken,
    int? damageDealt,
    int? staminaChange,
    bool? opening,
  }) {
    return ExchangeOutcome(
      quality: quality ?? this.quality,
      damageTaken: damageTaken ?? this.damageTaken,
      damageDealt: damageDealt ?? this.damageDealt,
      staminaChange: staminaChange ?? this.staminaChange,
      opening: opening ?? this.opening,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'quality': quality.name,
        'damageTaken': damageTaken,
        'damageDealt': damageDealt,
        'staminaChange': staminaChange,
        'opening': opening,
      };

  factory ExchangeOutcome.fromJson(Map<String, Object?> json) {
    return ExchangeOutcome(
      quality: readEnum(Quality.values, json, 'quality'),
      damageTaken: readInt(json, 'damageTaken'),
      damageDealt: readInt(json, 'damageDealt'),
      staminaChange: readInt(json, 'staminaChange'),
      opening: readBool(json, 'opening'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExchangeOutcome &&
        other.quality == quality &&
        other.damageTaken == damageTaken &&
        other.damageDealt == damageDealt &&
        other.staminaChange == staminaChange &&
        other.opening == opening;
  }

  @override
  int get hashCode => Object.hash(quality, damageTaken, damageDealt, staminaChange, opening);

  @override
  String toString() =>
      'ExchangeOutcome(${quality.name}, taken $damageTaken, dealt $damageDealt, stamina $staminaChange, opening $opening)';
}
