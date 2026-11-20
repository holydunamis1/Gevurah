import '../catalog/card_catalog.dart';
import '../catalog/struggle_catalog.dart';
import '../models/achievement_def.dart';
import '../models/exchange_outcome.dart';
import '../models/exchange_record.dart';
import '../models/fight_state.dart';
import '../models/progress.dart';
import '../models/struggle_def.dart';
import 'progression_rules.dart';

/// The local milestones. Names are never about worth or faith; they record play.
abstract final class AchievementCatalog {
  static const List<AchievementDef> all = <AchievementDef>[
    AchievementDef(id: 'first_win', ruleId: 'first_win'),
    AchievementDef(id: 'no_downs', ruleId: 'no_downs'),
    AchievementDef(id: 'perfect_run', ruleId: 'perfect_run'),
    AchievementDef(id: 'three_stars', ruleId: 'three_stars'),
    AchievementDef(id: 'got_back_up', ruleId: 'got_back_up'),
    AchievementDef(id: 'tier_1', ruleId: 'tier_1'),
    AchievementDef(id: 'tier_2', ruleId: 'tier_2'),
    AchievementDef(id: 'tier_3', ruleId: 'tier_3'),
    AchievementDef(id: 'tier_4', ruleId: 'tier_4'),
    AchievementDef(id: 'still_standing', ruleId: 'still_standing'),
    AchievementDef(id: 'trials_done', ruleId: 'trials_done'),
    AchievementDef(id: 'ten_cards', ruleId: 'ten_cards'),
    AchievementDef(id: 'twenty_stars', ruleId: 'twenty_stars'),
    AchievementDef(id: 'daily_3', ruleId: 'daily_3'),
    AchievementDef(id: 'daily_7', ruleId: 'daily_7'),
  ];

  static AchievementDef? byId(String id) {
    for (final AchievementDef a in all) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }
}

/// What the engine looks at: the saved career, and optionally the bout that
/// just finished and today's date key.
class AchievementContext {
  const AchievementContext({
    required this.progress,
    this.finalState,
    this.history = const <ExchangeRecord>[],
    this.todayKey,
  });

  final Progress progress;
  final FightState? finalState;
  final List<ExchangeRecord> history;
  final String? todayKey;
}

abstract final class AchievementsEngine {
  /// Perfect responses in a row that count as a perfect run.
  static const int perfectRunLength = 5;

  /// Ids newly earned: every rule that now holds and is not yet unlocked,
  /// in catalog order.
  static List<String> evaluate(AchievementContext c) {
    final List<String> fresh = <String>[];
    for (final AchievementDef a in AchievementCatalog.all) {
      if (c.progress.achievements.contains(a.id)) {
        continue;
      }
      if (_holds(a.ruleId, c)) {
        fresh.add(a.id);
      }
    }
    return fresh;
  }

  static bool _wonBout(AchievementContext c) {
    final FightState? s = c.finalState;
    return s != null && s.isFinished && ProgressionRules.isWin(s.end);
  }

  static bool _holds(String ruleId, AchievementContext c) {
    final Progress p = c.progress;
    switch (ruleId) {
      case 'first_win':
        return p.bouts.values.any((BoutRecord r) => r.wins > 0);
      case 'no_downs':
        return _wonBout(c) && c.finalState!.player.downs == 0;
      case 'perfect_run':
        return _longestPerfectRun(c.history) >= perfectRunLength;
      case 'three_stars':
        return p.bouts.values.any((BoutRecord r) => r.stars == 3);
      case 'got_back_up':
        return _wonBout(c) && c.finalState!.player.downs > 0;
      case 'tier_1':
      case 'tier_2':
      case 'tier_3':
      case 'tier_4':
        return p.tiersCleared.contains(int.parse(ruleId.substring(5)));
      case 'still_standing':
        return (p.bouts[StruggleCatalog.finalBout.id]?.wins ?? 0) > 0;
      case 'trials_done':
        return StruggleCatalog.trials.every((StruggleDef s) => (p.bouts[s.id]?.wins ?? 0) > 0);
      case 'ten_cards':
        return p.cardsEarned.where((String id) => !CardCatalog.starterIds.contains(id)).length >= 10;
      case 'twenty_stars':
        return p.totalStars >= 20;
      case 'daily_3':
        return _streak(c) >= 3;
      case 'daily_7':
        return _streak(c) >= 7;
    }
    return false;
  }

  static int _streak(AchievementContext c) {
    final String? today = c.todayKey;
    return today == null ? 0 : ProgressionRules.dailyStreak(c.progress, today);
  }

  static int _longestPerfectRun(List<ExchangeRecord> history) {
    int best = 0;
    int run = 0;
    for (final ExchangeRecord r in history) {
      if (r.outcome.quality == Quality.perfect) {
        run++;
        if (run > best) {
          best = run;
        }
      } else {
        run = 0;
      }
    }
    return best;
  }
}
