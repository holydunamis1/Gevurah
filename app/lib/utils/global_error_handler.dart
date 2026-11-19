import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';

/// Receives every uncaught error. [fatal] is true for errors that escaped
/// all Flutter handling (the full-screen fallback should show).
typedef ErrorSink = void Function(
  Object error,
  StackTrace? stack, {
  required bool fatal,
});

/// Installs the app-wide error hooks and routes them to one sink, which
/// applies the error taxonomy (log locally, degrade, or show the fallback).
abstract final class GlobalErrorHandler {
  static ErrorSink? _sink;

  /// Whether a sink is currently installed.
  static bool get isInstalled => _sink != null;

  static void install(ErrorSink sink) {
    _sink = sink;
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _sink?.call(details.exception, details.stack, fatal: false);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _sink?.call(error, stack, fatal: true);
      return true;
    };
  }

  /// Detaches the sink. The hooks stay in place but no longer forward.
  static void reset() {
    _sink = null;
  }
}
