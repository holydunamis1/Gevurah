import 'package:flutter/foundation.dart';

import '../core/logic/daily_seed.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/daily_challenge.dart';
import '../core/models/progress.dart';
import '../core/ports/clock_port.dart';
import 'flags_provider.dart';
import 'progress_provider.dart';

class DailyState {
  const DailyState({required this.challenge, required this.doneToday, required this.stars, required this.streak, required this.enabled});

  /// Today's opponent, the same for every player on the same date.
  final DailyChallenge challenge;
  final bool doneToday;
  final int stars;
  final int streak;

  /// False when the remote flag has switched the Daily Bout off.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is DailyState &&
      other.challenge == challenge &&
      other.doneToday == doneToday &&
      other.stars == stars &&
      other.streak == streak &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(challenge, doneToday, stars, streak, enabled);
}

/// Today's Daily Bout and the streak. Dates use the phone's local calendar day;
/// call [refresh] when the app resumes so a new day shows at once.
class DailyProvider extends ValueNotifier<DailyState> {
  DailyProvider({required ClockPort clock, required ProgressProvider progress, required FlagsProvider flags})
      : _clock = clock,
        _progress = progress,
        _flags = flags,
        super(_build(clock, progress.progress, flags.value.dailyBoutEnabled)) {
    progress.addListener(refresh);
    flags.addListener(refresh);
  }

  final ClockPort _clock;
  final ProgressProvider _progress;
  final FlagsProvider _flags;

  static DailyState _build(ClockPort clock, Progress p, bool enabled) {
    final DateTime now = clock.now();
    final DailyChallenge c = DailySeed.forDate(now);
    final List<DailyRecord> today = p.dailyHistory.where((DailyRecord d) => d.dateKey == c.dateKey).toList();
    final bool done = today.isNotEmpty && today.first.completed;
    return DailyState(
      challenge: c,
      doneToday: done,
      stars: done ? today.first.stars : 0,
      streak: ProgressionRules.dailyStreak(p, c.dateKey),
      enabled: enabled,
    );
  }

  void refresh() => value = _build(_clock, _progress.progress, _flags.value.dailyBoutEnabled);

  @override
  void dispose() {
    _progress.removeListener(refresh);
    _flags.removeListener(refresh);
    super.dispose();
  }
}
