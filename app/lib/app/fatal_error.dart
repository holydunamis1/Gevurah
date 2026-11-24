import 'package:flutter/foundation.dart';

import '../core/errors/app_error.dart';
import '../core/ports/log_port.dart';
import '../utils/global_error_handler.dart';

/// Whether the full-screen error fallback is showing. The app listens to it.
class FatalErrorHost extends ValueNotifier<bool> {
  FatalErrorHost() : super(false);

  void raise() => value = true;

  void clear() => value = false;
}

/// The one sink for uncaught errors (blueprint section 4). Every error goes to
/// the local log. Only an unexpected error that escaped all handling shows the
/// fallback; errors the app raises on purpose as recoverable or degraded
/// (declined notifications, a failed ad or save) never do.
ErrorSink fatalErrorSink(FatalErrorHost host, LogPort log) {
  return (Object error, StackTrace? stack, {required bool fatal}) {
    final bool handledOnPurpose = error is AppError && error.recoverable;
    log.log(
      fatal && !handledOnPurpose ? LogLevel.error : LogLevel.warning,
      fatal ? 'Uncaught error' : 'Framework error',
      error: error,
      stack: stack,
    );
    if (fatal && !handledOnPurpose) {
      host.raise();
    }
  };
}
