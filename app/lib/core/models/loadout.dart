import 'model_utils.dart';
import 'stance.dart';

/// The player's strategy choice: up to three verse cards and a stance.
class Loadout {
  const Loadout({required this.cardIds, required this.stance});

  const Loadout.empty()
      : cardIds = const <String>[],
        stance = Stance.steady;

  factory Loadout.fromJson(Map<String, Object?> json) => Loadout(
        cardIds: readStringList(json, 'cardIds'),
        stance: readEnum(Stance.values, json, 'stance'),
      );

  static const int maxCards = 3;

  final List<String> cardIds;
  final Stance stance;

  /// True when at most three distinct cards are equipped.
  bool get isValid => cardIds.length <= maxCards && cardIds.toSet().length == cardIds.length;

  bool get isFull => cardIds.length >= maxCards;

  /// A copy with [id] equipped, or this loadout if full or already equipped.
  Loadout equip(String id) {
    if (isFull || cardIds.contains(id)) {
      return this;
    }
    return copyWith(cardIds: <String>[...cardIds, id]);
  }

  /// A copy with [id] removed.
  Loadout unequip(String id) =>
      copyWith(cardIds: cardIds.where((String c) => c != id).toList(growable: false));

  Loadout copyWith({List<String>? cardIds, Stance? stance}) =>
      Loadout(cardIds: cardIds ?? this.cardIds, stance: stance ?? this.stance);

  Map<String, Object?> toJson() => <String, Object?>{'cardIds': cardIds, 'stance': stance.name};

  @override
  bool operator ==(Object other) =>
      other is Loadout && other.stance == stance && listEq(other.cardIds, cardIds);

  @override
  int get hashCode => Object.hash(stance, listHash(cardIds));
}
