import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/config/remote_flags.dart';
import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/core/ports/billing_port.dart';
import 'package:gevurah/platform/billing_service.dart';
import 'package:gevurah/platform/flags_service.dart';

import '../fakes/fakes.dart';

const String product = 'remove_ads';
const Duration quick = Duration(milliseconds: 30);

class FakeStore implements StoreDriver {
  final StreamController<StoreEvent> controller = StreamController<StoreEvent>.broadcast();
  bool available = true;
  bool canStart = true;
  bool restoreThrows = false;
  List<StoreEvent> onRestore = <StoreEvent>[];
  List<StoreEvent> onBuy = <StoreEvent>[];
  int restores = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> priceText(String productId) async => available ? r'$2.99' : null;

  @override
  Future<bool> buy(String productId) async {
    if (canStart) {
      for (final StoreEvent e in onBuy) {
        scheduleMicrotask(() => controller.add(e));
      }
    }
    return canStart;
  }

  @override
  Future<void> restore() async {
    restores++;
    if (restoreThrows) {
      throw StateError('store down');
    }
    for (final StoreEvent e in onRestore) {
      scheduleMicrotask(() => controller.add(e));
    }
  }

  @override
  Stream<StoreEvent> get events => controller.stream;
}

BillingService billing(FakeStore store, {FakeStorage? storage}) => BillingService(
      driver: store,
      productId: product,
      storage: storage,
      settleTimeout: quick,
      purchaseTimeout: quick,
    );

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 120));

void main() {
  group('BillingService', () {
    test('an owned purchase restored at launch removes ads and is cached', () async {
      final FakeStore store = FakeStore()..onRestore = <StoreEvent>[const StoreEvent(product, StoreEventKind.restored)];
      final FakeStorage storage = FakeStorage();
      final BillingService b = billing(store, storage: storage);
      await b.start();
      await settle();
      expect(await b.currentEntitlement(), Entitlement.adsRemoved);
      expect(storage.strings[BillingService.cacheKey], 'adsRemoved');
    });

    test('nothing owned means none', () async {
      final FakeStore store = FakeStore();
      final BillingService b = billing(store);
      await b.start();
      expect(await b.currentEntitlement(), Entitlement.unknown);
      await settle();
      expect(await b.currentEntitlement(), Entitlement.none);
    });

    test('an offline launch keeps a cached purchase', () async {
      final FakeStorage storage = FakeStorage()..strings[BillingService.cacheKey] = 'adsRemoved';
      final FakeStore store = FakeStore()..available = false;
      final BillingService b = billing(store, storage: storage);
      await b.start();
      await settle();
      expect(await b.currentEntitlement(), Entitlement.adsRemoved);
    });

    test('a store that answers nothing does not take a cached purchase away at launch', () async {
      final FakeStorage storage = FakeStorage()..strings[BillingService.cacheKey] = 'adsRemoved';
      final BillingService b = billing(FakeStore(), storage: storage);
      await b.start();
      await settle();
      expect(await b.currentEntitlement(), Entitlement.adsRemoved);
    });

    test('a store that throws leaves the answer unknown', () async {
      final FakeStore store = FakeStore()..restoreThrows = true;
      final BillingService b = billing(store, storage: FakeStorage());
      await b.start();
      await settle();
      expect(await b.currentEntitlement(), Entitlement.unknown);
    });

    test('buy: purchased, cancelled, error, pending, cannot start, unavailable', () async {
      final Map<StoreEventKind, PurchaseOutcome> expected = <StoreEventKind, PurchaseOutcome>{
        StoreEventKind.purchased: PurchaseOutcome.purchased,
        StoreEventKind.canceled: PurchaseOutcome.cancelled,
        StoreEventKind.error: PurchaseOutcome.failed,
        StoreEventKind.pending: PurchaseOutcome.pending,
      };
      for (final MapEntry<StoreEventKind, PurchaseOutcome> e in expected.entries) {
        final FakeStore store = FakeStore()..onBuy = <StoreEvent>[StoreEvent(product, e.key)];
        final BillingService b = billing(store);
        await b.start();
        await settle();
        expect(await b.buy(), e.value, reason: e.key.name);
        expect(await b.currentEntitlement(), e.key == StoreEventKind.purchased ? Entitlement.adsRemoved : Entitlement.none);
      }
      expect(await billing(FakeStore()..canStart = false).buy(), PurchaseOutcome.failed);
      expect(await billing(FakeStore()..available = false).buy(), PurchaseOutcome.failed);
    });

    test('a purchase that never reports back is pending', () async {
      expect(await billing(FakeStore()).buy(), PurchaseOutcome.pending);
    });

    test('buying again when already owned reports restored and does not charge', () async {
      final FakeStore store = FakeStore()..onRestore = <StoreEvent>[const StoreEvent(product, StoreEventKind.restored)];
      final BillingService b = billing(store);
      await b.start();
      await settle();
      expect(await b.buy(), PurchaseOutcome.restored);
    });

    test('restore: found, nothing, unavailable, failing', () async {
      final FakeStore owned = FakeStore()..onRestore = <StoreEvent>[const StoreEvent(product, StoreEventKind.restored)];
      expect(await billing(owned).restore(), PurchaseOutcome.restored);
      expect(await billing(FakeStore()).restore(), PurchaseOutcome.nothingToRestore);
      expect(await billing(FakeStore()..available = false).restore(), PurchaseOutcome.failed);
      expect(await billing(FakeStore()..restoreThrows = true).restore(), PurchaseOutcome.failed);
    });

    test('events for other products are ignored', () async {
      final FakeStore store = FakeStore()..onBuy = <StoreEvent>[const StoreEvent('other', StoreEventKind.purchased)];
      final BillingService b = billing(store);
      await b.start();
      await settle();
      expect(await b.buy(), PurchaseOutcome.pending);
      expect(await b.currentEntitlement(), Entitlement.none);
    });

    test('a pending purchase that later clears is reported on the stream', () async {
      final FakeStore store = FakeStore()..onBuy = <StoreEvent>[const StoreEvent(product, StoreEventKind.pending)];
      final BillingService b = billing(store);
      await b.start();
      await settle();
      final List<Entitlement> seen = <Entitlement>[];
      final StreamSubscription<Entitlement> sub = b.entitlementChanges.listen(seen.add);
      expect(await b.buy(), PurchaseOutcome.pending);
      store.controller.add(const StoreEvent(product, StoreEventKind.purchased));
      await settle();
      expect(seen, <Entitlement>[Entitlement.adsRemoved]);
      await sub.cancel();
      await b.dispose();
    });

    test('availability and price come from the store and fail quietly', () async {
      final BillingService b = billing(FakeStore());
      expect(await b.isAvailable(), true);
      expect(await b.priceText(), r'$2.99');
      expect(await billing(FakeStore()..available = false).priceText(), isNull);
    });
  });

  group('FlagsService', () {
    const String url = 'https://example.com/flags.json';

    test('no address means no request and the defaults', () async {
      int calls = 0;
      final FlagsService s = FlagsService(storage: FakeStorage(), url: '', fetcher: (Uri u, Duration t) async {
        calls++;
        return '{}';
      });
      expect(await s.load(), RemoteFlags.defaults);
      expect(calls, 0);
    });

    test('only https addresses are fetched', () async {
      int calls = 0;
      Future<String> fetch(Uri u, Duration t) async {
        calls++;
        return '{}';
      }

      for (final String bad in <String>['http://example.com/f.json', 'ftp://x/y', 'https://', 'nonsense']) {
        expect(await FlagsService(storage: FakeStorage(), url: bad, fetcher: fetch).load(), RemoteFlags.defaults);
      }
      expect(calls, 0);
    });

    test('a good answer is used and cached', () async {
      final FakeStorage storage = FakeStorage();
      final FlagsService s = FlagsService(storage: storage, url: url, fetcher: (Uri u, Duration t) async => '{"interstitialsEnabled": false}');
      expect((await s.load()).interstitialsEnabled, false);
      expect(storage.strings[FlagsService.cacheKey], contains('interstitialsEnabled'));
    });

    test('a failure or bad answer falls back to the last good flags, then defaults', () async {
      final FakeStorage storage = FakeStorage();
      await FlagsService(storage: storage, url: url, fetcher: (Uri u, Duration t) async => '{"adsEnabled": false}').load();
      for (final Future<String> Function(Uri, Duration) fetch in <Future<String> Function(Uri, Duration)>[
        (Uri u, Duration t) async => throw StateError('offline'),
        (Uri u, Duration t) async => 'not json',
        (Uri u, Duration t) async => '[]',
      ]) {
        expect((await FlagsService(storage: storage, url: url, fetcher: fetch).load()).adsEnabled, false);
      }
      expect(await FlagsService(storage: FakeStorage(), url: url, fetcher: (Uri u, Duration t) async => 'x').load(), RemoteFlags.defaults);
    });

    test('damaged cache and storage failures still give the defaults', () async {
      final FakeStorage storage = FakeStorage()..strings[FlagsService.cacheKey] = '{{{';
      expect(await FlagsService(storage: storage, url: '').load(), RemoteFlags.defaults);
      final FakeStorage broken = FakeStorage()..failReads = true;
      expect(await FlagsService(storage: broken, url: '').load(), RemoteFlags.defaults);
      final FakeStorage noWrite = FakeStorage()..failWrites = true;
      expect((await FlagsService(storage: noWrite, url: url, fetcher: (Uri u, Duration t) async => '{"rewardedEnabled": false}').load()).rewardedEnabled, false);
    });
  });

  test('StorageError is what a failing store raises elsewhere', () {
    expect(const StorageError('x').message, 'x');
  });
}
