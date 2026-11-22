import 'package:flutter/foundation.dart';

import '../core/logic/achievements_engine.dart';
import '../core/models/exchange_record.dart';
import '../core/models/fight_state.dart';
import 'progress_provider.dart';

/// Checks the achievement rules after a bout and records new ones. The value
/// is the queue of newly unlocked ids waiting to be shown as a quiet toast.
class AchievementsProvider extends ValueNotifier<List<String>> {
  AchievementsProvider(this._progress) : super(const <String>[]);

  final ProgressProvider _progress;

  /// Unlocks whatever now holds. Returns the new ids (possibly none).
  Future<List<String>> evaluate({FightState? finalState, List<ExchangeRecord> history = const <ExchangeRecord>[], String? todayKey}) async {
    final List<String> fresh = AchievementsEngine.evaluate(
      AchievementContext(progress: _progress.progress, finalState: finalState, history: history, todayKey: todayKey),
    );
    if (fresh.isEmpty) {
      return fresh;
    }
    await _progress.recordAchievements(fresh);
    value = <String>[...value, ...fresh];
    return fresh;
  }

  /// Takes the next id to show, or null when the queue is empty.
  String? takeNext() {
    if (value.isEmpty) {
      return null;
    }
    final String next = value.first;
    value = value.sublist(1);
    return next;
  }
}
