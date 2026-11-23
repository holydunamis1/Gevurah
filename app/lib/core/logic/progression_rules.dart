import '../catalog/card_catalog.dart';
import '../catalog/struggle_catalog.dart';
import '../models/daily_challenge.dart';
import '../models/exchange_outcome.dart';
import '../models/exchange_record.dart';
import '../models/fight_config.dart';
import '../models/fight_state.dart';
import '../models/player_state.dart';
import '../models/progress.dart';
import '../models/struggle_def.dart';
import '../models/verse_card_def.dart';

/// What the player can open, derived from [Progress] alone.
class Unlocks {
  const Unlocks({
    required this.careerOpen,
    required this.tiersCleared,
    required this.trialsOpen,
    required this.trialIdsOpen,
    required this.sparringOpen,
    required this.enduranceOpen,
  });

  /// Career struggle ids the player may fight now (one after another).
  final List<String> careerOpen;
  final List<int> tiersCleared;
  final bool trialsOpen;
  final List<String> trialIdsOpen;
  final bool sparringOpen;
  final bool enduranceOpen;

  /// Daily Bout and Training are always open.
  bool get dailyOpen => true;
  bool get trainingOpen => true;
}

/// Tuning for the star rules.
abstract final class StarTuning {
  /// Stars are earned for skill only: a win, no downs, then Resolve and perfects.
  static const int resolveForThirdStar = 50;
  static const int perfectPercentForThirdStar = 40;
}

/// Pure rules for stars, cards, unlocks and saved progress.
abstract final class ProgressionRules {
  static bool isWin(FightEnd? end) => end == FightEnd.struggleDefeated || end == FightEnd.decisionWon;

  /// Stars for a finished bout (0 to 3). A loss earns none.
  /// One for the win, two with no downs, three with no downs, at least half the
  /// Resolve left and at least 40 percent of responses perfect.
  static int stars(FightState state, List<ExchangeRecord> history) {
    if (!state.isFinished || !isWin(state.end)) {
      return 0;
    }
    if (state.player.downs > 0) {
      return 1;
    }
    final int perfectPercent = perfectResponsePercent(history);
    if (state.player.resolve >= StarTuning.resolveForThirdStar &&
        perfectPercent >= StarTuning.perfectPercentForThirdStar) {
      return 3;
    }
    return 2;
  }

  /// Percent of exchanges answered perfectly (0 when there were none).
  static int perfectResponsePercent(List<ExchangeRecord> history) {
    if (history.isEmpty) {
      return 0;
    }
    final int perfect = history.where((ExchangeRecord r) => r.outcome.quality == Quality.perfect).length;
    return (perfect * 100) ~/ history.length;
  }

  /// The card won by beating [struggleId], or null if it has none.
  static VerseCardDef? cardFor(String struggleId) => CardCatalog.earnedBy(struggleId);

  /// Which tiers have every career struggle won.
  static List<int> tiersClearedFor(Progress p) {
    final List<int> cleared = <int>[];
    for (int tier = 1; tier <= 4; tier++) {
      final List<StruggleDef> members = StruggleCatalog.careerTier(tier);
      if (members.isNotEmpty && members.every((StruggleDef s) => _won(p, s.id))) {
        cleared.add(tier);
      }
    }
    return cleared;
  }

  static bool _won(Progress p, String id) => (p.bouts[id]?.wins ?? 0) > 0;

  /// Unlocks. Career runs in order: a struggle opens once the one before it is
  /// won. Trials open after tier 1, Sparring after the first win, Endurance
  /// after tier 2. Trials run in order too.
  static Unlocks unlocksFor(Progress p) {
    final List<String> career = <String>[];
    for (int i = 0; i < StruggleCatalog.career.length; i++) {
      final StruggleDef s = StruggleCatalog.career[i];
      if (i == 0 || _won(p, StruggleCatalog.career[i - 1].id)) {
        career.add(s.id);
      }
    }
    final List<int> tiers = tiersClearedFor(p);
    final bool trials = tiers.contains(1);
    final List<String> trialIds = <String>[];
    if (trials) {
      for (int i = 0; i < StruggleCatalog.trials.length; i++) {
        if (i == 0 || _won(p, StruggleCatalog.trials[i - 1].id)) {
          trialIds.add(StruggleCatalog.trials[i].id);
        }
      }
    }
    return Unlocks(
      careerOpen: career,
      tiersCleared: tiers,
      trialsOpen: trials,
      trialIdsOpen: trialIds,
      sparringOpen: p.bouts.values.any((BoutRecord r) => r.wins > 0),
      enduranceOpen: tiers.contains(2),
    );
  }

  /// True if the player may start [struggleId] in [mode].
  static bool canFight(Progress p, FightMode mode, String struggleId) {
    final Unlocks u = unlocksFor(p);
    switch (mode) {
      case FightMode.journey:
        return u.careerOpen.contains(struggleId);
      case FightMode.trials:
        return u.trialIdsOpen.contains(struggleId);
      case FightMode.sparring:
        return u.sparringOpen && p.bouts.containsKey(struggleId);
      case FightMode.daily:
      case FightMode.training:
        return StruggleCatalog.byId(struggleId) != null;
      case FightMode.endurance:
        return u.enduranceOpen;
    }
  }

  /// Applies a finished bout to the saved career. Journey and Trials record
  /// wins, best stars and the card; Sparring records wins and best stars; the
  /// other modes change nothing here (Daily is recorded by [applyDaily]).
  static Progress applyResult(Progress p, FightConfig config, FightState state, List<ExchangeRecord> history) {
    if (!state.isFinished) {
      return p;
    }
    switch (config.mode) {
      case FightMode.journey:
      case FightMode.trials:
      case FightMode.sparring:
        break;
      case FightMode.endurance:
        return history.length > p.enduranceBest ? p.copyWith(enduranceBest: history.length) : p;
      case FightMode.daily:
      case FightMode.training:
        return p;
    }
    final bool won = isWin(state.end);
    final int earnedStars = stars(state, history);
    final BoutRecord old = p.bouts[config.struggleId] ?? const BoutRecord(stars: 0, wins: 0);
    final BoutRecord next = BoutRecord(
      stars: earnedStars > old.stars ? earnedStars : old.stars,
      wins: won ? old.wins + 1 : old.wins,
    );
    final Map<String, BoutRecord> bouts = Map<String, BoutRecord>.of(p.bouts);
    bouts[config.struggleId] = next;
    List<String> cards = p.cardsEarned;
    if (won && config.mode != FightMode.sparring) {
      final VerseCardDef? card = cardFor(config.struggleId);
      if (card != null && !cards.contains(card.id)) {
        cards = <String>[...cards, card.id];
      }
    }
    final Progress updated = p.copyWith(bouts: bouts, cardsEarned: cards);
    return updated.copyWith(tiersCleared: tiersClearedFor(updated));
  }

  /// Records a Daily Bout. A completed day stays completed and keeps its best stars.
  static Progress applyDaily(Progress p, DailyChallenge challenge, {required bool completed, required int stars}) {
    final List<DailyRecord> history = List<DailyRecord>.of(p.dailyHistory);
    final int i = history.indexWhere((DailyRecord d) => d.dateKey == challenge.dateKey);
    if (i < 0) {
      history.add(DailyRecord(dateKey: challenge.dateKey, completed: completed, stars: completed ? stars : 0));
    } else {
      final DailyRecord old = history[i];
      history[i] = DailyRecord(
        dateKey: old.dateKey,
        completed: old.completed || completed,
        stars: completed && stars > old.stars ? stars : old.stars,
      );
    }
    history.sort((DailyRecord a, DailyRecord b) => a.dateKey.compareTo(b.dateKey));
    return p.copyWith(dailyHistory: history);
  }

  /// Consecutive completed days ending today, or ending yesterday if today is
  /// not done yet. Uses date keys (yyyy-mm-dd), never time of day.
  static int dailyStreak(Progress p, String todayKey) {
    final Set<String> done = <String>{
      for (final DailyRecord d in p.dailyHistory)
        if (d.completed) d.dateKey,
    };
    final DateTime? today = _parseKey(todayKey);
    if (today == null) {
      return 0;
    }
    DateTime cursor = today;
    if (!done.contains(_key(cursor))) {
      cursor = _addDays(cursor, -1);
    }
    int streak = 0;
    while (done.contains(_key(cursor))) {
      streak++;
      cursor = _addDays(cursor, -1);
    }
    return streak;
  }

  static DateTime _addDays(DateTime d, int n) => DateTime.utc(d.year, d.month, d.day + n);

  static DateTime? _parseKey(String key) {
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (m == null) {
      return null;
    }
    return DateTime.utc(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  static String _key(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  /// Resolve on a won bout is read from the final state; exposed for results.
  static int resolveLeft(FightState s) => s.player.resolve.clamp(0, PlayerState.maxResolve);
}
