import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ports/consent_port.dart';

/// The calls the service needs from the consent platform.
abstract class UmpDriver {
  /// Asks for fresh consent information. False when it could not be fetched (offline).
  Future<bool> requestInfoUpdate();

  Future<void> loadAndShowFormIfRequired();

  /// Read from what the platform saved, so it works offline.
  Future<bool> canRequestAds();

  Future<bool> privacyOptionsRequired();

  Future<void> showPrivacyOptions();
}

/// Google's User Messaging Platform.
class GoogleUmpDriver implements UmpDriver {
  @override
  Future<bool> requestInfoUpdate() {
    final Completer<bool> done = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => done.complete(true),
      (FormError error) => done.complete(false),
    );
    return done.future;
  }

  @override
  Future<void> loadAndShowFormIfRequired() {
    final Completer<void> done = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) => done.complete());
    return done.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() {
    final Completer<void> done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) => done.complete());
    return done.future;
  }
}

/// The consent gate. Every ad request waits for this to say yes. A failed or
/// offline refresh never overrides what the platform saved: the saved
/// canRequestAds value is read either way.
class ConsentService implements ConsentPort {
  ConsentService({UmpDriver? driver, this.timeout = const Duration(seconds: 10)}) : _driver = driver ?? GoogleUmpDriver();

  final UmpDriver _driver;
  final Duration timeout;

  Future<ConsentState> _read() async {
    try {
      return ConsentState(
        canRequestAds: await _driver.canRequestAds(),
        privacyOptionsRequired: await _driver.privacyOptionsRequired(),
      );
    } on Object {
      return ConsentState.unknown;
    }
  }

  @override
  Future<ConsentState> refresh() async {
    bool updated = false;
    try {
      updated = await _driver.requestInfoUpdate().timeout(timeout, onTimeout: () => false);
    } on Object {
      updated = false;
    }
    if (updated) {
      try {
        await _driver.loadAndShowFormIfRequired();
      } on Object {
        // A form that fails to show leaves the saved state in charge.
      }
    }
    return _read();
  }

  @override
  Future<ConsentState> showPrivacyOptions() async {
    try {
      await _driver.showPrivacyOptions();
    } on Object {
      // Fall through to read whatever state the platform holds.
    }
    return _read();
  }
}
