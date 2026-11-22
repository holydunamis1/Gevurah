import 'package:flutter/foundation.dart';

import '../core/ports/consent_port.dart';

/// The ad-consent state. `canRequestAds` is the one gate every ad reads.
class ConsentProvider extends ValueNotifier<ConsentState> {
  ConsentProvider(this._consent) : super(ConsentState.unknown);

  final ConsentPort _consent;

  bool get canRequestAds => value.canRequestAds;

  /// Whether Settings should show "Privacy options".
  bool get privacyOptionsRequired => value.privacyOptionsRequired;

  /// Run at every launch. A failure leaves the last known state in place.
  Future<void> refresh() async {
    try {
      value = await _consent.refresh();
    } on Object {
      // Never block the app on consent.
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      value = await _consent.showPrivacyOptions();
    } on Object {
      // The form could not be shown; nothing changes.
    }
  }
}
