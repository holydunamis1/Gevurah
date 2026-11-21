import '../models/verse_ref.dart';

/// Curated references are English references. Some bundled texts number a few
/// Psalms later (the heading counts as verse 1). This maps between the two.
/// The values come from tools/scripture/alignment.json and a test compares them.
abstract final class VerseNumberMap {
  static const Map<String, int> _psalmShifts = <String, int>{
    '19.18': 1, '19.19': 1, '19.30': 1, '19.31': 1, '19.34': 1,
    '19.40': 1, '19.42': 1, '19.46': 1, '19.51': 2, '19.54': 2,
    '19.55': 1, '19.56': 1, '19.57': 1, '19.61': 1, '19.62': 1,
  };

  /// Per language: chapter key (`book.chapter`) to how many verses later its text sits.
  static const Map<String, Map<String, int>> shifts = <String, Map<String, int>>{
    'fr': _psalmShifts,
    'ar': _psalmShifts,
    'zh': _psalmShifts,
  };

  static int _shift(VerseRef ref, String language) => shifts[language]?['${ref.book}.${ref.chapter}'] ?? 0;

  /// The reference as numbered in [language].
  static VerseRef toLocal(VerseRef english, String language) {
    final int s = _shift(english, language);
    return s == 0 ? english : VerseRef(english.book, english.chapter, english.verse + s);
  }

  /// The English reference for one numbered in [language].
  static VerseRef toEnglish(VerseRef local, String language) {
    final int s = _shift(local, language);
    return s == 0 || local.verse - s < 1 ? local : VerseRef(local.book, local.chapter, local.verse - s);
  }
}
