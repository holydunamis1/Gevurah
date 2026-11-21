/// Ad loading and showing. Callers check consent and entitlement first; the
/// adapter initialises the SDK only when told to.
abstract class AdsPort {
  /// Starts the ad SDK. Called only after consent allows requests.
  Future<void> initialize();

  Future<void> loadInterstitial();

  bool get interstitialReady;

  /// Shows a loaded interstitial. Returns false if none was ready.
  Future<bool> showInterstitial();

  Future<void> loadRewarded();

  bool get rewardedReady;

  /// Shows a rewarded ad. True only when the player earned the reward.
  Future<bool> showRewarded();
}
