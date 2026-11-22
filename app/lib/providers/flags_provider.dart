import 'package:flutter/foundation.dart';

import '../core/config/remote_flags.dart';

/// The remote switches. Defaults apply until a fetch finishes, and whenever
/// it fails; the fetch never blocks the app.
class FlagsProvider extends ValueNotifier<RemoteFlags> {
  FlagsProvider(this._fetch) : super(RemoteFlags.defaults);

  final Future<RemoteFlags> Function() _fetch;

  Future<void> refresh() async {
    try {
      value = await _fetch();
    } on Object {
      // Keep whatever is in use.
    }
  }
}
