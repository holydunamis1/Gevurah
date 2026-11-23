import 'loadout.dart';
import 'model_utils.dart';

/// Best result and win count for one struggle.
class BoutRecord {
  const BoutRecord({required this.stars, required this.wins});

  factory BoutRecord.fromJson(Map<String, Object?> json) {
    final int stars = readInt(json, 'stars');
    if (stars < 0 || stars > 3) {
      throw FormatException('Stars out of range: $stars');
    }
    return BoutRecord(stars: stars, wins: readInt(json, 'wins'));
  }

  /// Best stars, 0 to 3. Stars measure skill only.
  final int stars;
  final int wins;

  Map<String, Object?> toJson() => <String, Object?>{'stars': stars, 'wins': wins};

  @override
  bool operator ==(Object other) => other is BoutRecord && other.stars == stars && other.wins == wins;

  @override
  int get hashCode => Object.hash(stars, wins);
}

/// One day of Daily Bout history.
class DailyRecord {
  const DailyRecord({required this.dateKey, required this.completed, required this.stars});

  factory DailyRecord.fromJson(Map<String, Object?> json) => DailyRecord(
        dateKey: readString(json, 'dateKey'),
        completed: readBool(json, 'completed'),
        stars: readInt(json, 'stars'),
      );

  /// "yyyy-mm-dd".
  final String dateKey;
  final bool completed;
  final int stars;

  Map<String, Object?> toJson() =>
      <String, Object?>{'dateKey': dateKey, 'completed': completed, 'stars': stars};

  @override
  bool operator ==(Object other) =>
      other is DailyRecord && other.dateKey == dateKey && other.completed == completed && other.stars == stars;

  @override
  int get hashCode => Object.hash(dateKey, completed, stars);
}

/// The saved career. Stored as one JSON file with [schemaVersion].
class Progress {
  const Progress({
    required this.schemaVersion,
    required this.bouts,
    required this.tiersCleared,
    required this.cardsEarned,
    required this.dailyHistory,
    required this.achievements,
    required this.loadout,
    this.enduranceBest = 0,
  });

  /// A new player's progress with the starter cards owned.
  factory Progress.initial({required List<String> starterCardIds}) => Progress(
        schemaVersion: currentSchemaVersion,
        bouts: const <String, BoutRecord>{},
        tiersCleared: const <int>[],
        cardsEarned: List<String>.unmodifiable(starterCardIds),
        dailyHistory: const <DailyRecord>[],
        achievements: const <String>[],
        loadout: const Loadout.empty(),
      );

  factory Progress.fromJson(Map<String, Object?> json) {
    final Map<String, BoutRecord> bouts = <String, BoutRecord>{};
    for (final MapEntry<String, Object?> e in readMap(json, 'bouts').entries) {
      final Object? v = e.value;
      if (v is! Map<String, Object?>) {
        throw FormatException('Bad bout record for "${e.key}"');
      }
      bouts[e.key] = BoutRecord.fromJson(v);
    }
    final List<int> tiers = <int>[];
    for (final Object? v in readList(json, 'tiersCleared')) {
      if (v is! int) {
        throw FormatException('Bad tier "$v"');
      }
      tiers.add(v);
    }
    final List<DailyRecord> daily = <DailyRecord>[];
    for (final Object? v in readList(json, 'dailyHistory')) {
      if (v is! Map<String, Object?>) {
        throw FormatException('Bad daily record');
      }
      daily.add(DailyRecord.fromJson(v));
    }
    return Progress(
      schemaVersion: readInt(json, 'schemaVersion'),
      bouts: bouts,
      tiersCleared: tiers,
      cardsEarned: readStringList(json, 'cardsEarned'),
      dailyHistory: daily,
      achievements: readStringList(json, 'achievements'),
      loadout: Loadout.fromJson(readMap(json, 'loadout')),
      enduranceBest: json['enduranceBest'] is int ? json['enduranceBest']! as int : 0,
    );
  }

  /// The schema the app writes. Migrations in p2c move older files up to it.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;

  /// Keyed by struggle id.
  final Map<String, BoutRecord> bouts;
  final List<int> tiersCleared;
  final List<String> cardsEarned;
  final List<DailyRecord> dailyHistory;
  final List<String> achievements;
  final Loadout loadout;

  /// The most exchanges answered in one Endurance run. Optional in older
  /// saves, which read as zero.
  final int enduranceBest;

  bool ownsCard(String id) => cardsEarned.contains(id);

  int starsFor(String struggleId) => bouts[struggleId]?.stars ?? 0;

  int get totalStars => bouts.values.fold(0, (int sum, BoutRecord r) => sum + r.stars);

  Progress copyWith({
    int? schemaVersion,
    Map<String, BoutRecord>? bouts,
    List<int>? tiersCleared,
    List<String>? cardsEarned,
    List<DailyRecord>? dailyHistory,
    List<String>? achievements,
    Loadout? loadout,
    int? enduranceBest,
  }) {
    return Progress(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      bouts: bouts ?? this.bouts,
      tiersCleared: tiersCleared ?? this.tiersCleared,
      cardsEarned: cardsEarned ?? this.cardsEarned,
      dailyHistory: dailyHistory ?? this.dailyHistory,
      achievements: achievements ?? this.achievements,
      loadout: loadout ?? this.loadout,
      enduranceBest: enduranceBest ?? this.enduranceBest,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'bouts': <String, Object?>{for (final MapEntry<String, BoutRecord> e in bouts.entries) e.key: e.value.toJson()},
        'tiersCleared': tiersCleared,
        'cardsEarned': cardsEarned,
        'dailyHistory': dailyHistory.map((DailyRecord d) => d.toJson()).toList(),
        'achievements': achievements,
        'loadout': loadout.toJson(),
        'enduranceBest': enduranceBest,
      };

  @override
  bool operator ==(Object other) =>
      other is Progress &&
      other.schemaVersion == schemaVersion &&
      mapEq(other.bouts, bouts) &&
      listEq(other.tiersCleared, tiersCleared) &&
      listEq(other.cardsEarned, cardsEarned) &&
      listEq(other.dailyHistory, dailyHistory) &&
      listEq(other.achievements, achievements) &&
      other.loadout == loadout &&
      other.enduranceBest == enduranceBest;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        mapHash(bouts),
        listHash(tiersCleared),
        listHash(cardsEarned),
        listHash(dailyHistory),
        listHash(achievements),
        loadout,
        enduranceBest,
      );
}
