/// Ad unit ids. Until Ak supplies production ids only Google's sample ids are
/// used (they always serve test ads). Copied from AdMob's documentation:
/// developers.google.com/admob/android/test-ads and .../ios/test-ads.
class AdUnitIds {
  const AdUnitIds({required this.banner, required this.interstitial, required this.rewarded});

  /// Google's sample ids: anchored adaptive banner, interstitial, rewarded.
  static const AdUnitIds androidTest = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/9214589741',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const AdUnitIds iosTest = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/2435281174',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  );

  final String banner;
  final String interstitial;
  final String rewarded;

  /// Production ids when supplied for a release build, otherwise the samples.
  static AdUnitIds select({required bool android, bool release = false, AdUnitIds? production}) {
    if (release && production != null) {
      return production;
    }
    return android ? androidTest : iosTest;
  }
}
