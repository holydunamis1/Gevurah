import 'model_utils.dart';

/// The 66 books in canonical order (English names). Book number is index + 1.
const List<String> canonBooks = <String>[
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth',
  '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
  'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
  'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
  'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah',
  'Malachi', 'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians',
  '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
  '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
  '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation',
];

/// A canonical verse key: book number (1 to 66), chapter and verse, all from 1.
/// It is language-independent; a per-language map links it to local numbering.
class VerseRef {
  const VerseRef(this.book, this.chapter, this.verse);

  /// Reads "Philippians 4:13", "1 Corinthians 10:13", or the numeric key "50.4.13".
  factory VerseRef.parse(String text) {
    final String s = text.trim();
    final RegExpMatch? numeric = RegExp(r'^(\d{1,2})\.(\d{1,3})\.(\d{1,3})$').firstMatch(s);
    if (numeric != null) {
      return VerseRef._checked(
        int.parse(numeric.group(1)!),
        int.parse(numeric.group(2)!),
        int.parse(numeric.group(3)!),
        text,
      );
    }
    final RegExpMatch? named = RegExp(r'^(.+?)\s+(\d{1,3}):(\d{1,3})$').firstMatch(s);
    if (named == null) {
      throw FormatException('Not a verse reference: "$text"');
    }
    final int index = canonBooks.indexOf(named.group(1)!);
    if (index < 0) {
      throw FormatException('Unknown book "${named.group(1)}" in "$text"');
    }
    return VerseRef._checked(index + 1, int.parse(named.group(2)!), int.parse(named.group(3)!), text);
  }

  factory VerseRef._checked(int book, int chapter, int verse, String source) {
    if (book < 1 || book > canonBooks.length || chapter < 1 || verse < 1) {
      throw FormatException('Verse reference out of range: "$source"');
    }
    return VerseRef(book, chapter, verse);
  }

  factory VerseRef.fromJson(Map<String, Object?> json) =>
      VerseRef._checked(readInt(json, 'book'), readInt(json, 'chapter'), readInt(json, 'verse'), '$json');

  final int book;
  final int chapter;
  final int verse;

  /// English book name.
  String get bookName => canonBooks[book - 1];

  /// Stable numeric key such as "50.4.13".
  String get key => '$book.$chapter.$verse';

  Map<String, Object?> toJson() => <String, Object?>{'book': book, 'chapter': chapter, 'verse': verse};

  @override
  String toString() => '$bookName $chapter:$verse';

  @override
  bool operator ==(Object other) =>
      other is VerseRef && other.book == book && other.chapter == chapter && other.verse == verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);
}
