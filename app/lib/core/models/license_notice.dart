import 'model_utils.dart';

/// The notice a bundled source requires, shown on the license screen.
class LicenseNotice {
  const LicenseNotice({
    required this.id,
    required this.sourceName,
    required this.license,
    required this.attribution,
    required this.link,
  });

  factory LicenseNotice.fromJson(Map<String, Object?> json) => LicenseNotice(
        id: readString(json, 'id'),
        sourceName: readString(json, 'sourceName'),
        license: readString(json, 'license'),
        attribution: readString(json, 'attribution'),
        link: readString(json, 'link'),
      );

  final String id;
  final String sourceName;
  final String license;

  /// The exact attribution line the license requires; may be empty.
  final String attribution;
  final String link;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'sourceName': sourceName,
        'license': license,
        'attribution': attribution,
        'link': link,
      };

  @override
  bool operator ==(Object other) =>
      other is LicenseNotice &&
      other.id == id &&
      other.sourceName == sourceName &&
      other.license == license &&
      other.attribution == attribution &&
      other.link == link;

  @override
  int get hashCode => Object.hash(id, sourceName, license, attribution, link);
}
