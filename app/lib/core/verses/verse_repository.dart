import 'dart:convert';

import '../errors/app_error.dart';
import '../logic/seeded_rng.dart';
import '../models/curated_verse.dart';
import '../models/license_notice.dart';
import '../models/model_utils.dart';
import '../models/verse.dart';
import '../models/verse_ref.dart';
import 'verse_source.dart';

/// Reads a bundled text asset by path. The app passes a function backed by
/// its asset bundle; tests pass one backed by memory.
typedef AssetTextLoader = Future<String> Function(String path);

/// The bundled curated verses, in the player's language with English as the
/// fallback. Nothing here needs the network.
class VerseRepository implements VerseSource {
  VerseRepository(this._load);

  static const List<String> languages = <String>['en', 'es', 'fr', 'de', 'pt', 'ar', 'hi', 'zh', 'he', 'ja', 'ko'];
  static const String fallbackLanguage = 'en';

  final AssetTextLoader _load;

  List<CuratedVerse>? _curated;
  final Map<String, _Bundle> _bundles = <String, _Bundle>{};

  Future<List<CuratedVerse>> curated() async {
    final List<CuratedVerse>? cached = _curated;
    if (cached != null) {
      return cached;
    }
    final Object? decoded = await _decode('assets/verses/curated.json');
    final List<CuratedVerse> list = <CuratedVerse>[
      for (final Object? v in readList(decoded! as Map<String, Object?>, 'verses'))
        CuratedVerse.fromJson(v! as Map<String, Object?>),
    ];
    return _curated = List<CuratedVerse>.unmodifiable(list);
  }

  Future<Object?> _decode(String path) async {
    try {
      return jsonDecode(await _load(path));
    } on Object catch (e) {
      throw StorageError('Could not read bundled data "$path"', cause: e);
    }
  }

  Future<_Bundle> _bundle(String language) async {
    final String lang = languages.contains(language) ? language : fallbackLanguage;
    final _Bundle? cached = _bundles[lang];
    if (cached != null) {
      return cached;
    }
    try {
      final Map<String, Object?> json = (await _decode('assets/verses/$lang.json'))! as Map<String, Object?>;
      return _bundles[lang] = _Bundle(
        language: readString(json, 'language'),
        translationId: readString(json, 'translationId'),
        verses: readMap(json, 'verses'),
      );
    } on StorageError {
      if (lang == fallbackLanguage) {
        rethrow;
      }
      return _bundle(fallbackLanguage);
    } on FormatException catch (e) {
      if (lang == fallbackLanguage) {
        throw StorageError('Bundled verses for "$lang" are damaged', cause: e);
      }
      return _bundle(fallbackLanguage);
    }
  }

  Verse? _from(_Bundle b, VerseRef ref) {
    final Object? text = b.verses[ref.key];
    if (text is! String || text.trim().isEmpty) {
      return null;
    }
    return Verse(ref: ref, text: text, language: b.language, translationId: b.translationId);
  }

  @override
  Future<Verse?> byRef(VerseRef ref, String language) async {
    final Verse? v = _from(await _bundle(language), ref);
    if (v != null) {
      return v;
    }
    return _from(await _bundle(fallbackLanguage), ref);
  }

  @override
  Future<List<Verse>> byMoment(VerseMoment moment, String language) async {
    final List<CuratedVerse> list = (await curated()).where((CuratedVerse c) => c.fits(moment)).toList()
      ..sort((CuratedVerse a, CuratedVerse b) => a.id.compareTo(b.id));
    final List<Verse> out = <Verse>[];
    for (final CuratedVerse c in list) {
      final Verse? v = await byRef(c.ref, language);
      if (v != null) {
        out.add(v);
      }
    }
    return out;
  }

  /// One verse for [moment], chosen by [seed] so a bout or a day always shows
  /// the same one. Ids in [exclude] are skipped while others remain.
  Future<Verse?> pick(VerseMoment moment, String language, {required int seed, Set<String> exclude = const <String>{}}) async {
    final List<CuratedVerse> all = (await curated()).where((CuratedVerse c) => c.fits(moment)).toList()
      ..sort((CuratedVerse a, CuratedVerse b) => a.id.compareTo(b.id));
    if (all.isEmpty) {
      return null;
    }
    final List<CuratedVerse> fresh = all.where((CuratedVerse c) => !exclude.contains(c.id)).toList();
    final List<CuratedVerse> pool = fresh.isEmpty ? all : fresh;
    return byRef(pool[SeededRng(seed).nextInt(pool.length)].ref, language);
  }

  /// The verse shown on a struggle's opponent card.
  Future<Verse?> preBoutFor(String struggleId, String language) => _byId('prebout_$struggleId', language);

  /// The verse on a verse card (`card_<card id>`).
  Future<Verse?> cardVerse(String cardId, String language) => _byId('card_$cardId', language);

  Future<Verse?> _byId(String id, String language) async {
    for (final CuratedVerse c in await curated()) {
      if (c.id == id) {
        return byRef(c.ref, language);
      }
    }
    return null;
  }

  Future<LicenseNotice?> noticeFor(String language) async {
    final String lang = languages.contains(language) ? language : fallbackLanguage;
    final Object? json = await _decode('assets/licenses/$lang.json');
    return LicenseNotice.fromJson(json! as Map<String, Object?>);
  }

  /// Every bundled source's notice, once each, for the licence screen.
  Future<List<LicenseNotice>> allNotices() async {
    final Map<String, LicenseNotice> byId = <String, LicenseNotice>{};
    for (final String lang in languages) {
      final LicenseNotice? n = await noticeFor(lang);
      if (n != null) {
        byId[n.id] = n;
      }
    }
    return byId.values.toList(growable: false);
  }
}

class _Bundle {
  const _Bundle({required this.language, required this.translationId, required this.verses});

  final String language;
  final String translationId;
  final Map<String, Object?> verses;
}
