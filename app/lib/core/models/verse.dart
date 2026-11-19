import 'model_utils.dart';
import 'verse_ref.dart';

/// One verse in one language: its reference and the exact source text.
class Verse {
  const Verse({
    required this.ref,
    required this.text,
    required this.language,
    required this.translationId,
  });

  factory Verse.fromJson(Map<String, Object?> json) => Verse(
        ref: VerseRef.fromJson(readMap(json, 'ref')),
        text: readString(json, 'text'),
        language: readString(json, 'language'),
        translationId: readString(json, 'translationId'),
      );

  final VerseRef ref;

  /// The text exactly as extracted from the source; never altered.
  final String text;

  /// Language code such as "en".
  final String language;

  /// Identifies the translation, which links to its license notice.
  final String translationId;

  Map<String, Object?> toJson() => <String, Object?>{
        'ref': ref.toJson(),
        'text': text,
        'language': language,
        'translationId': translationId,
      };

  @override
  bool operator ==(Object other) =>
      other is Verse &&
      other.ref == ref &&
      other.text == text &&
      other.language == language &&
      other.translationId == translationId;

  @override
  int get hashCode => Object.hash(ref, text, language, translationId);
}
