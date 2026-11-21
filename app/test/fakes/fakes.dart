import 'dart:async';

import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/core/ports/ads_port.dart';
import 'package:gevurah/core/ports/audio_port.dart';
import 'package:gevurah/core/ports/billing_port.dart';
import 'package:gevurah/core/ports/clock_port.dart';
import 'package:gevurah/core/ports/connectivity_port.dart';
import 'package:gevurah/core/ports/consent_port.dart';
import 'package:gevurah/core/ports/haptics_port.dart';
import 'package:gevurah/core/ports/log_port.dart';
import 'package:gevurah/core/ports/notification_port.dart';
import 'package:gevurah/core/ports/storage_port.dart';

/// In-memory storage with switches to make reads or writes fail.
class FakeStorage implements StoragePort {
  final Map<String, String> strings = <String, String>{};
  final Map<String, String> files = <String, String>{};
  final List<String> writes = <String>[];
  bool failReads = false;
  bool failWrites = false;
  final Set<String> failWriteFor = <String>{};

  @override
  Future<String?> readString(String key) async {
    if (failReads) {
      throw const StorageError('read failed');
    }
    return strings[key];
  }

  @override
  Future<void> writeString(String key, String value) async {
    if (failWrites) {
      throw const StorageError('write failed');
    }
    strings[key] = value;
  }

  @override
  Future<void> removeString(String key) async => strings.remove(key);

  @override
  Future<String?> readFile(String name) async {
    if (failReads) {
      throw const StorageError('read failed');
    }
    return files[name];
  }

  @override
  Future<void> writeFile(String name, String contents) async {
    if (failWrites || failWriteFor.contains(name)) {
      throw const StorageError('write failed');
    }
    writes.add(name);
    files[name] = contents;
  }

  @override
  Future<void> removeFile(String name) async => files.remove(name);
}

class FakeClock implements ClockPort {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

class FakeLog implements LogPort {
  final List<String> lines = <String>[];

  @override
  void log(LogLevel level, String message, {Object? error, StackTrace? stack}) {
    lines.add('${level.name}: $message');
  }

  @override
  Future<String> exportText() async => lines.join('\n');
}

class FakeHaptics implements HapticsPort {
  final List<HapticKind> played = <HapticKind>[];

  @override
  Future<void> play(HapticKind kind) async => played.add(kind);
}

class FakeAudio implements AudioPort {
  final List<String> played = <String>[];
  final List<String> preloaded = <String>[];
  String? loop;
  bool muted = false;

  @override
  Future<void> preload(List<String> ids) async => preloaded.addAll(ids);

  @override
  Future<void> play(String id, {double volume = 1}) async {
    if (!muted) {
      played.add(id);
    }
  }

  @override
  Future<void> startLoop(String id, {double volume = 0.5}) async => loop = muted ? null : id;

  @override
  Future<void> stopLoop() async => loop = null;

  @override
  void setMuted(bool value) {
    muted = value;
    if (value) {
      loop = null;
    }
  }
}

class FakeConnectivity implements ConnectivityPort {
  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  bool online = true;

  void setOnline(bool value) {
    online = value;
    _changes.add(value);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;
}

class FakeConsent implements ConsentPort {
  FakeConsent(this.state);

  ConsentState state;
  int refreshes = 0;

  @override
  Future<ConsentState> refresh() async {
    refreshes++;
    return state;
  }

  @override
  Future<ConsentState> showPrivacyOptions() async => state;
}

class FakeAds implements AdsPort {
  bool initialized = false;
  bool _interstitial = false;
  bool _rewarded = false;
  bool rewardEarned = true;
  int interstitialsShown = 0;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> loadInterstitial() async => _interstitial = true;

  @override
  bool get interstitialReady => _interstitial;

  @override
  Future<bool> showInterstitial() async {
    if (!_interstitial) {
      return false;
    }
    _interstitial = false;
    interstitialsShown++;
    return true;
  }

  @override
  Future<void> loadRewarded() async => _rewarded = true;

  @override
  bool get rewardedReady => _rewarded;

  @override
  Future<bool> showRewarded() async {
    if (!_rewarded) {
      return false;
    }
    _rewarded = false;
    return rewardEarned;
  }
}

class FakeBilling implements BillingPort {
  Entitlement entitlement = Entitlement.none;
  bool available = true;
  PurchaseOutcome nextBuy = PurchaseOutcome.purchased;
  final StreamController<Entitlement> _changes = StreamController<Entitlement>.broadcast();

  void emit(Entitlement e) {
    entitlement = e;
    _changes.add(e);
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> priceText() async => available ? r'$2.99' : null;

  @override
  Future<Entitlement> currentEntitlement() async => entitlement;

  @override
  Future<PurchaseOutcome> buy() async {
    if (nextBuy == PurchaseOutcome.purchased) {
      entitlement = Entitlement.adsRemoved;
    }
    return nextBuy;
  }

  @override
  Future<PurchaseOutcome> restore() async {
    return entitlement == Entitlement.adsRemoved ? PurchaseOutcome.restored : PurchaseOutcome.nothingToRestore;
  }

  @override
  Stream<Entitlement> get entitlementChanges => _changes.stream;
}

class FakeNotifications implements NotificationPort {
  bool granted = false;
  bool grantOnRequest = true;
  int? scheduledMinute;
  String? scheduledTitle;

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async => granted = grantOnRequest;

  @override
  Future<void> scheduleDaily({required int minuteOfDay, required String title, required String body}) async {
    scheduledMinute = minuteOfDay;
    scheduledTitle = title;
  }

  @override
  Future<void> cancelDaily() async => scheduledMinute = null;
}
