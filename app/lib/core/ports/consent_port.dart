/// Where the consent platform (UMP) stands.
class ConsentState {
  const ConsentState({required this.canRequestAds, required this.privacyOptionsRequired});

  /// Nothing known yet: no ads until a refresh says otherwise.
  static const ConsentState unknown = ConsentState(canRequestAds: false, privacyOptionsRequired: false);

  final bool canRequestAds;
  final bool privacyOptionsRequired;

  @override
  bool operator ==(Object other) =>
      other is ConsentState &&
      other.canRequestAds == canRequestAds &&
      other.privacyOptionsRequired == privacyOptionsRequired;

  @override
  int get hashCode => Object.hash(canRequestAds, privacyOptionsRequired);

  @override
  String toString() => 'ConsentState(canRequestAds: $canRequestAds, privacyOptionsRequired: $privacyOptionsRequired)';
}

abstract class ConsentPort {
  /// Refreshes consent, shows the form when one is required, and returns the
  /// result. When offline it returns the last state the platform saved.
  Future<ConsentState> refresh();

  /// Shows the privacy options form (Settings). Returns the new state.
  Future<ConsentState> showPrivacyOptions();
}
