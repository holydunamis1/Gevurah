import 'model_utils.dart';
import 'verse_ref.dart';

/// The pauses in which a verse may appear. Never live action.
enum VerseMoment { preBout, corner, tenCount, win, loss, daily, card }

/// Which verse fits which moment.
class CuratedVerse {
  const CuratedVerse({required this.id, required this.ref, required this.moments});

  factory CuratedVerse.fromJson(Map<String, Object?> json) {
    final List<VerseMoment> moments = <VerseMoment>[];
    for (final String name in readStringList(json, 'moments')) {
      moments.add(
        VerseMoment.values.firstWhere(
          (VerseMoment m) => m.name == name,
          orElse: () => throw FormatException('Unknown moment "$name"'),
        ),
      );
    }
    return CuratedVerse(
      id: readString(json, 'id'),
      ref: VerseRef.fromJson(readMap(json, 'ref')),
      moments: moments,
    );
  }

  final String id;
  final VerseRef ref;
  final List<VerseMoment> moments;

  bool fits(VerseMoment m) => moments.contains(m);

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ref': ref.toJson(),
        'moments': moments.map((VerseMoment m) => m.name).toList(),
      };

  @override
  bool operator ==(Object other) =>
      other is CuratedVerse && other.id == id && other.ref == ref && listEq(other.moments, moments);

  @override
  int get hashCode => Object.hash(id, ref, listHash(moments));
}
