/// Constants Ak supplies. Anything not yet known is empty and the code that
/// reads it does nothing until it is filled in.
abstract final class AppConfig {
  static const String supportEmail = 'stmakarios@gmail.com';

  /// The one non-consumable product, registered in both stores before release.
  static const String removeAdsProductId = 'remove_ads';

  /// The live website (Cloudflare). The privacy and support pages sit under it.
  static const String websiteUrl = 'https://gevurah.holydunamis1.workers.dev';

  static const String privacyUrl = '$websiteUrl/privacy';

  /// The support page carries the support email; no other page does.
  static const String supportUrl = '$websiteUrl/support';

  /// Where flags.json lives (https only). Empty means no request is ever made.
  static const String flagsUrl = '';

  /// At most one interstitial in this time, counted from the last one or from app start.
  static const Duration interstitialGap = Duration(minutes: 10);
}
