import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../errors/app_error.dart';
import '../models/model_utils.dart';
import '../models/progress.dart';
import 'migrations.dart';

/// How a decode ended.
enum ProgressDecodeStatus { ok, migrated, newerVersion }

class ProgressDecoded {
  const ProgressDecoded(this.status, this.storedVersion, this.progress);

  final ProgressDecodeStatus status;
  final int storedVersion;

  /// Null only for [ProgressDecodeStatus.newerVersion]: the app cannot read it
  /// and must not overwrite it.
  final Progress? progress;
}

/// Saved progress as versioned JSON with a checksum. The envelope holds the
/// payload as a string so the checksum never depends on re-encoding.
abstract final class ProgressCodec {
  static const int envelopeFormat = 1;

  static String encode(Progress progress) {
    final String payload = jsonEncode(progress.toJson());
    return jsonEncode(<String, Object?>{
      'format': envelopeFormat,
      'checksum': _checksum(payload),
      'payload': payload,
    });
  }

  /// Throws a [StorageError] when the text is not a valid save.
  static ProgressDecoded decode(String text, {Migrator migrator = Migrator.standard}) {
    try {
      final Object? outer = jsonDecode(text);
      if (outer is! Map<String, Object?>) {
        throw const FormatException('Not an object');
      }
      if (readInt(outer, 'format') != envelopeFormat) {
        throw const FormatException('Unknown format');
      }
      final String payload = readString(outer, 'payload');
      if (readString(outer, 'checksum') != _checksum(payload)) {
        throw const FormatException('Checksum mismatch');
      }
      final Object? inner = jsonDecode(payload);
      if (inner is! Map<String, Object?>) {
        throw const FormatException('Payload is not an object');
      }
      final int version = readInt(inner, 'schemaVersion');
      if (version > migrator.currentVersion) {
        return ProgressDecoded(ProgressDecodeStatus.newerVersion, version, null);
      }
      final Map<String, Object?> current = migrator.migrate(inner);
      return ProgressDecoded(
        version == migrator.currentVersion ? ProgressDecodeStatus.ok : ProgressDecodeStatus.migrated,
        version,
        Progress.fromJson(current),
      );
    } on StorageError {
      rethrow;
    } on FormatException catch (e) {
      throw StorageError('Saved progress is damaged: ${e.message}', cause: e);
    } on TypeError catch (e) {
      throw StorageError('Saved progress is damaged', cause: e);
    }
  }

  static String _checksum(String payload) => sha256.convert(utf8.encode(payload)).toString();
}
