import 'dart:async';
import 'dart:io';

import '../core/ports/clock_port.dart';
import '../core/ports/log_port.dart';

/// A small rotating log in the app's private folder, with no third-party
/// service. The player can send the exported text by email.
class LogService implements LogPort {
  LogService({required Future<Directory> Function() directory, ClockPort clock = const SystemClock(), this.maxBytes = 64 * 1024})
      : _directory = directory,
        _clock = clock;

  final Future<Directory> Function() _directory;
  final ClockPort _clock;

  /// The current file rotates to the previous one when it passes this size.
  final int maxBytes;

  static const String currentName = 'log.txt';
  static const String previousName = 'log.1.txt';
  static const int maxExportChars = 12000;

  Future<void> _chain = Future<void>.value();

  @override
  void log(LogLevel level, String message, {Object? error, StackTrace? stack}) {
    final String stamp = _clock.now().toIso8601String();
    final StringBuffer line = StringBuffer('$stamp ${level.name.toUpperCase()} $message');
    if (error != null) {
      line.write(' | $error');
    }
    if (stack != null) {
      line.write('\n${stack.toString().split('\n').take(6).join('\n')}');
    }
    line.writeln();
    final String text = line.toString();
    _chain = _chain.then((_) => _append(text)).catchError((Object _) {
      // Logging must never throw.
    });
  }

  Future<void> _append(String text) async {
    final Directory dir = await _directory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final File current = File('${dir.path}/$currentName');
    if (current.existsSync() && current.lengthSync() > maxBytes) {
      await current.rename('${dir.path}/$previousName');
    }
    await current.writeAsString(text, mode: FileMode.append, flush: true);
  }

  /// Completes when every queued line has been written.
  Future<void> flush() => _chain;

  @override
  Future<String> exportText() async {
    await _chain;
    final StringBuffer out = StringBuffer('Gevurah Boxing log\n');
    try {
      final Directory dir = await _directory();
      for (final String name in <String>[previousName, currentName]) {
        final File f = File('${dir.path}/$name');
        if (f.existsSync()) {
          out.write(await f.readAsString());
        }
      }
    } on FileSystemException {
      out.writeln('(the log could not be read)');
    }
    final String text = out.toString();
    return text.length <= maxExportChars ? text : text.substring(text.length - maxExportChars);
  }
}
