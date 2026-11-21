abstract class ConnectivityPort {
  Future<bool> isOnline();

  /// Emits whenever the state changes.
  Stream<bool> get onlineChanges;
}
