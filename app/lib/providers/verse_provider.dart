import 'package:flutter/foundation.dart';

import '../core/models/curated_verse.dart';
import '../core/models/license_notice.dart';
import '../core/logic/seeded_rng.dart';
import '../core/models/verse.dart';
import '../core/verses/verse_repository.dart';
import 'locale_provider.dart';

/// Verses in the player's language. Every call returns null rather than
/// throwing, so a missing verse only means a quieter screen. The value is the
/// language in use, so screens rebuild when it changes.
class VerseProvider extends ValueNotifier<String> {
  VerseProvider(this._repo, this._locale) : super(_locale.value) {
    _locale.addListener(_sync);
  }

  final VerseRepository _repo;
  final LocaleProvider _locale;
  final Set<String> _recent = <String>{};

  static const int _recentLimit = 6;

  void _sync() => value = _locale.value;

  /// A verse for [moment], avoiding the last few shown, chosen by [seed] so
  /// the same seed always gives the same verse in the same state.
  Future<Verse?> forMoment(VerseMoment moment, {required int seed}) async {
    try {
      final List<Verse> all = await _repo.byMoment(moment, value);
      if (all.isEmpty) {
        return null;
      }
      final List<Verse> fresh = all.where((Verse v) => !_recent.contains(v.ref.toString())).toList();
      final List<Verse> pool = fresh.isEmpty ? all : fresh;
      final Verse v = pool[SeededRng(seed).nextInt(pool.length)];
      _recent.add(v.ref.toString());
      if (_recent.length > _recentLimit) {
        _recent.remove(_recent.first);
      }
      return v;
    } on Object {
      return null;
    }
  }

  /// Every verse bundled for [moment], in a stable order, for the library.
  Future<List<Verse>> all(VerseMoment moment) async {
    try {
      return await _repo.byMoment(moment, value);
    } on Object {
      return const <Verse>[];
    }
  }

  /// The license notice for every bundled source; empty if they cannot be read.
  Future<List<LicenseNotice>> notices() async {
    try {
      return await _repo.allNotices();
    } on Object {
      return const <LicenseNotice>[];
    }
  }

  Future<Verse?> preBout(String struggleId) => _guard(() => _repo.preBoutFor(struggleId, value));

  Future<Verse?> card(String cardId) => _guard(() => _repo.cardVerse(cardId, value));

  Future<Verse?> _guard(Future<Verse?> Function() f) async {
    try {
      return await f();
    } on Object {
      return null;
    }
  }

  @override
  void dispose() {
    _locale.removeListener(_sync);
    super.dispose();
  }
}
