import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/config/app_config.dart';
import 'package:gevurah/core/config/remote_flags.dart';

void main() {
  test('defaults turn everything on', () {
    expect(RemoteFlags.defaults.adsEnabled, true);
    expect(RemoteFlags.defaults.interstitialsEnabled, true);
    expect(RemoteFlags.defaults.rewardedEnabled, true);
    expect(RemoteFlags.defaults.dailyBoutEnabled, true);
  });

  test('json round trips', () {
    const RemoteFlags f = RemoteFlags(interstitialsEnabled: false, dailyBoutEnabled: false);
    expect(RemoteFlags.fromJson(f.toJson()), f);
    expect(RemoteFlags.fromJson(f.toJson()).hashCode, f.hashCode);
  });

  test('missing, extra and wrongly typed fields keep safe defaults', () {
    final RemoteFlags f = RemoteFlags.fromJson(<String, Object?>{'adsEnabled': 'no', 'rewardedEnabled': false, 'other': 1});
    expect(f.adsEnabled, true);
    expect(f.rewardedEnabled, false);
    expect(f.interstitialsEnabled, true);
  });

  test('config holds the locked values', () {
    expect(AppConfig.supportEmail, 'stmakarios@gmail.com');
    expect(AppConfig.interstitialGap, const Duration(minutes: 10));
    expect(AppConfig.flagsUrl.isEmpty || AppConfig.flagsUrl.startsWith('https://'), true);
  });
}
