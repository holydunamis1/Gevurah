enum LogLevel { debug, info, warning, error }

/// A local log with no third-party service. Nothing leaves the device unless
/// the player sends the exported text by email.
abstract class LogPort {
  void log(LogLevel level, String message, {Object? error, StackTrace? stack});

  /// The recent log as plain text, for an email report.
  Future<String> exportText();
}
