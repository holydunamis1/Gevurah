import 'model_utils.dart';

/// The Daily Bout for one date: the same for everyone.
class DailyChallenge {
  const DailyChallenge({required this.dateKey, required this.seed, required this.struggleId});

  factory DailyChallenge.fromJson(Map<String, Object?> json) {
    final String key = readString(json, 'dateKey');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
      throw FormatException('Date key must be yyyy-mm-dd, got "$key"');
    }
    return DailyChallenge(dateKey: key, seed: readInt(json, 'seed'), struggleId: readString(json, 'struggleId'));
  }

  /// "yyyy-mm-dd".
  final String dateKey;
  final int seed;
  final String struggleId;

  Map<String, Object?> toJson() => <String, Object?>{'dateKey': dateKey, 'seed': seed, 'struggleId': struggleId};

  @override
  bool operator ==(Object other) =>
      other is DailyChallenge && other.dateKey == dateKey && other.seed == seed && other.struggleId == struggleId;

  @override
  int get hashCode => Object.hash(dateKey, seed, struggleId);
}
