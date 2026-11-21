import '../models/curated_verse.dart';
import '../models/verse.dart';
import '../models/verse_ref.dart';

/// Where verses come from. The bundled set is the first source; a downloaded
/// full Bible can be added later without changing any screen.
abstract class VerseSource {
  /// The verse at [ref] in [language], or null when this source has none.
  Future<Verse?> byRef(VerseRef ref, String language);

  /// The verses that fit [moment], in a stable order.
  Future<List<Verse>> byMoment(VerseMoment moment, String language);
}
