import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/ports/connectivity_port.dart';

/// Whether the device has any network. Only a hint for ads: the ad SDK
/// still decides for itself.
class ConnectivityService implements ConnectivityPort {
  ConnectivityService({
    Future<List<ConnectivityResult>> Function()? check,
    this.changes,
  }) : _check = check ?? Connectivity().checkConnectivity;

  final Future<List<ConnectivityResult>> Function() _check;
  final Stream<List<ConnectivityResult>>? changes;

  static bool _online(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    try {
      return _online(await _check());
    } on Object {
      // If the plugin fails, do not block anything on it.
      return true;
    }
  }

  @override
  Stream<bool> get onlineChanges =>
      (changes ?? Connectivity().onConnectivityChanged).map(_online).distinct();
}
