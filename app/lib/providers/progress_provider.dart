import 'package:flutter/foundation.dart';

import '../core/catalog/card_catalog.dart';
import '../core/errors/app_error.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/daily_challenge.dart';
import '../core/models/exchange_record.dart';
import '../core/models/fight_config.dart';
import '../core/models/fight_state.dart';
import '../core/models/loadout.dart';
import '../core/models/progress.dart';
import '../core/storage/progress_store.dart';

enum ProgressStatus { loading, ready, readOnly }

enum ProgressNotice { none, recoveredFromBackup, startedClean }

class ProgressState {
  const ProgressState({
    required this.progress,
    this.status = ProgressStatus.loading,
    this.notice = ProgressNotice.none,
    this.saveFailed = false,
  });

  final Progress progress;
  final ProgressStatus status;

  /// A one-time message about a recovered or reset save, until dismissed.
  final ProgressNotice notice;

  /// True when the last save failed; progress still counts for this session.
  final bool saveFailed;

  ProgressState copyWith({Progress? progress, ProgressStatus? status, ProgressNotice? notice, bool? saveFailed}) =>
      ProgressState(
        progress: progress ?? this.progress,
        status: status ?? this.status,
        notice: notice ?? this.notice,
        saveFailed: saveFailed ?? this.saveFailed,
      );

  @override
  bool operator ==(Object other) =>
      other is ProgressState &&
      other.progress == progress &&
      other.status == status &&
      other.notice == notice &&
      other.saveFailed == saveFailed;

  @override
  int get hashCode => Object.hash(progress, status, notice, saveFailed);
}

/// What a finished bout changed.
class FightResultApplied {
  const FightResultApplied({required this.before, required this.after, required this.stars, required this.newCardId, required this.saved});

  final Progress before;
  final Progress after;
  final int stars;

  /// The card won, or null if none was new.
  final String? newCardId;
  final bool saved;
}

/// The saved career. Every change applies at once and is then saved in order;
/// a failed save raises [ProgressState.saveFailed] and the next change retries.
class ProgressProvider extends ValueNotifier<ProgressState> {
  ProgressProvider(this._store)
      : super(ProgressState(progress: Progress.initial(starterCardIds: CardCatalog.starterIds)));

  final ProgressStore _store;
  Future<void> _chain = Future<void>.value();

  Progress get progress => value.progress;

  Future<void> load() async {
    final ProgressLoad l = await _store.load();
    ProgressNotice notice = ProgressNotice.none;
    if (l.status == ProgressStoreStatus.recoveredFromBackup) {
      notice = ProgressNotice.recoveredFromBackup;
    } else if (l.status == ProgressStoreStatus.startedClean) {
      notice = ProgressNotice.startedClean;
    }
    value = ProgressState(
      progress: l.progress,
      status: l.canSave ? ProgressStatus.ready : ProgressStatus.readOnly,
      notice: notice,
    );
  }

  void dismissNotice() => value = value.copyWith(notice: ProgressNotice.none);

  Future<bool> _apply(Progress next) {
    value = value.copyWith(progress: next);
    return retrySave();
  }

  /// Saves the current progress, after any save already running.
  Future<bool> retrySave() {
    final Future<bool> result = _chain.then((_) => _saveLatest());
    _chain = result.then((_) {});
    return result;
  }

  Future<bool> _saveLatest() async {
    try {
      final bool saved = await _store.save(value.progress);
      if (!saved) {
        value = value.copyWith(status: ProgressStatus.readOnly);
        return false;
      }
      if (value.saveFailed) {
        value = value.copyWith(saveFailed: false);
      }
      return true;
    } on StorageError {
      value = value.copyWith(saveFailed: true);
      return false;
    }
  }

  /// Records a finished bout: wins, best stars, the card, tiers cleared.
  Future<FightResultApplied> applyFightResult(FightConfig config, FightState finalState, List<ExchangeRecord> history) async {
    final Progress before = value.progress;
    final Progress after = ProgressionRules.applyResult(before, config, finalState, history);
    final List<String> added = after.cardsEarned.where((String id) => !before.cardsEarned.contains(id)).toList();
    final bool saved = identical(after, before) ? true : await _apply(after);
    return FightResultApplied(
      before: before,
      after: after,
      stars: ProgressionRules.stars(finalState, history),
      newCardId: added.isEmpty ? null : added.first,
      saved: saved,
    );
  }

  Future<bool> applyDaily(DailyChallenge challenge, {required bool completed, required int stars}) =>
      _apply(ProgressionRules.applyDaily(value.progress, challenge, completed: completed, stars: stars));

  /// Marks a missed Daily day completed (the rewarded restore).
  Future<bool> restoreDailyDay(String dayKey) => _apply(ProgressionRules.restoreDay(value.progress, dayKey));

  /// Adds newly earned achievements (no repeats).
  Future<bool> recordAchievements(List<String> ids) {
    final List<String> fresh = ids.where((String id) => !value.progress.achievements.contains(id)).toSet().toList();
    if (fresh.isEmpty) {
      return Future<bool>.value(true);
    }
    return _apply(value.progress.copyWith(achievements: <String>[...value.progress.achievements, ...fresh]));
  }

  /// Saves the loadout, keeping only earned, known cards, at most three.
  Future<bool> setLoadout(Loadout loadout) {
    final List<String> ok = <String>[];
    for (final String id in loadout.cardIds) {
      if (ok.length < Loadout.maxCards &&
          !ok.contains(id) &&
          value.progress.cardsEarned.contains(id) &&
          CardCatalog.byId(id) != null) {
        ok.add(id);
      }
    }
    final Loadout clean = Loadout(cardIds: ok, stance: loadout.stance);
    if (clean == value.progress.loadout) {
      return Future<bool>.value(true);
    }
    return _apply(value.progress.copyWith(loadout: clean));
  }
}
