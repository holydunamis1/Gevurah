import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/config/remote_flags.dart';
import '../core/ports/log_port.dart';
import '../core/ports/storage_port.dart';

/// Fetches a small text file from [uri] within [timeout].
typedef TextFetcher = Future<String> Function(Uri uri, Duration timeout);

const int _maxFlagsBytes = 16 * 1024;

Future<String> _httpFetch(Uri uri, Duration timeout) async {
  final HttpClient client = HttpClient()..connectionTimeout = timeout;
  try {
    final HttpClientRequest request = await client.getUrl(uri).timeout(timeout);
    final HttpClientResponse response = await request.close().timeout(timeout);
    if (response.statusCode != 200) {
      throw HttpException('Status ${response.statusCode}', uri: uri);
    }
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in response.timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > _maxFlagsBytes) {
        throw HttpException('Response too large', uri: uri);
      }
    }
    return utf8.decode(bytes);
  } finally {
    client.close(force: true);
  }
}

/// The remote switch. Any failure keeps the last good answer, or the defaults.
class FlagsService {
  FlagsService({
    required this.storage,
    required this.url,
    this.fetcher = _httpFetch,
    this.timeout = const Duration(seconds: 5),
    this.log,
  });

  static const String cacheKey = 'flags_cache';

  final StoragePort storage;

  /// https address of flags.json, or empty for no request at all.
  final String url;
  final TextFetcher fetcher;
  final Duration timeout;
  final LogPort? log;

  RemoteFlags? _parse(String? text) {
    if (text == null) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(text);
      return decoded is Map<String, Object?> ? RemoteFlags.fromJson(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  Future<RemoteFlags> _cached() async {
    try {
      return _parse(await storage.readString(cacheKey)) ?? RemoteFlags.defaults;
    } on Object {
      return RemoteFlags.defaults;
    }
  }

  /// The flags to use now: fresh when the fetch works, else cached, else defaults.
  Future<RemoteFlags> load() async {
    final Uri? uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return _cached();
    }
    try {
      final String text = await fetcher(uri, timeout);
      final RemoteFlags? fresh = _parse(text);
      if (fresh == null) {
        return await _cached();
      }
      try {
        await storage.writeString(cacheKey, jsonEncode(fresh.toJson()));
      } on Object {
        // A failed cache write does not matter.
      }
      return fresh;
    } on Object catch (e) {
      log?.log(LogLevel.info, 'Flags not fetched', error: e);
      return _cached();
    }
  }
}
