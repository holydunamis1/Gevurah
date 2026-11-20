import '../catalog/struggle_catalog.dart';
import '../models/daily_challenge.dart';
import '../models/struggle_def.dart';
import 'seeded_rng.dart';

/// The Daily Bout: the same seed and struggle for everyone on a given date.
abstract final class DailySeed {
  /// Date key `yyyy-mm-dd` from the calendar date as given (the caller passes
  /// the player's local date; time of day is ignored).
  static String dateKey(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }

  /// 32-bit FNV-1a of the key. Written out so it never depends on the
  /// platform's String.hashCode.
  static int seedFor(String key) {
    int hash = 0x811C9DC5;
    final String text = 'gevurah-daily-$key';
    for (final int unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Every struggle except the final bout is a possible daily opponent.
  static List<StruggleDef> get pool =>
      StruggleCatalog.all.where((StruggleDef s) => !s.isFinal).toList(growable: false);

  static DailyChallenge forDate(DateTime date) {
    final String key = dateKey(date);
    final int seed = seedFor(key);
    final List<StruggleDef> candidates = pool;
    final StruggleDef pick = candidates[SeededRng(seed).nextInt(candidates.length)];
    return DailyChallenge(dateKey: key, seed: seed, struggleId: pick.id);
  }
}
