/// The error taxonomy in code (blueprint section 4).
enum ErrorKind { userRecoverable, thirdPartyDegraded, storageDegraded, fatal }

/// An error the app handles on purpose. Pure Dart.
sealed class AppError implements Exception {
  const AppError(this.message, {this.cause});

  final String message;

  /// The underlying error, for the local log only; never shown to the player.
  final Object? cause;

  ErrorKind get kind;

  /// True when the app can carry on and the player can fix it.
  bool get recoverable => kind != ErrorKind.fatal;

  /// True when trying again can succeed.
  bool get retriable => kind == ErrorKind.storageDegraded || kind == ErrorKind.thirdPartyDegraded;

  @override
  String toString() => '$runtimeType($message)';
}

/// The player did something the app cannot do yet, such as declining notifications.
final class UserRecoverableError extends AppError {
  const UserRecoverableError(super.message, {super.cause});

  @override
  ErrorKind get kind => ErrorKind.userRecoverable;
}

/// A third-party piece failed, such as the ad SDK. The slot collapses; nothing blocks.
final class ThirdPartyError extends AppError {
  const ThirdPartyError(super.message, {super.cause});

  @override
  ErrorKind get kind => ErrorKind.thirdPartyDegraded;
}

/// Storage failed. The app keeps working in memory and shows a warning.
final class StorageError extends AppError {
  const StorageError(super.message, {super.cause});

  @override
  ErrorKind get kind => ErrorKind.storageDegraded;
}

/// An unexpected failure: full-screen fallback with Retry and a report link.
final class FatalError extends AppError {
  const FatalError(super.message, {super.cause});

  @override
  ErrorKind get kind => ErrorKind.fatal;
}
