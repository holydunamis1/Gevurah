/// Switches fetched from a small public file so a broken feature can be turned
/// off without a release. Every field has a safe default.
class RemoteFlags {
  const RemoteFlags({
    this.adsEnabled = true,
    this.interstitialsEnabled = true,
    this.rewardedEnabled = true,
    this.dailyBoutEnabled = true,
  });

  static const RemoteFlags defaults = RemoteFlags();

  final bool adsEnabled;
  final bool interstitialsEnabled;
  final bool rewardedEnabled;
  final bool dailyBoutEnabled;

  /// Reads whatever is usable. A missing or wrongly typed field keeps its default.
  factory RemoteFlags.fromJson(Map<String, Object?> json) {
    bool flag(String key) {
      final Object? v = json[key];
      return v is bool ? v : true;
    }

    return RemoteFlags(
      adsEnabled: flag('adsEnabled'),
      interstitialsEnabled: flag('interstitialsEnabled'),
      rewardedEnabled: flag('rewardedEnabled'),
      dailyBoutEnabled: flag('dailyBoutEnabled'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'adsEnabled': adsEnabled,
        'interstitialsEnabled': interstitialsEnabled,
        'rewardedEnabled': rewardedEnabled,
        'dailyBoutEnabled': dailyBoutEnabled,
      };

  @override
  bool operator ==(Object other) =>
      other is RemoteFlags &&
      other.adsEnabled == adsEnabled &&
      other.interstitialsEnabled == interstitialsEnabled &&
      other.rewardedEnabled == rewardedEnabled &&
      other.dailyBoutEnabled == dailyBoutEnabled;

  @override
  int get hashCode => Object.hash(adsEnabled, interstitialsEnabled, rewardedEnabled, dailyBoutEnabled);
}
