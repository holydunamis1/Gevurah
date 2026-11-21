import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/ports/billing_port.dart';
import '../core/ports/log_port.dart';
import '../core/ports/storage_port.dart';

enum StoreEventKind { purchased, restored, pending, canceled, error }

class StoreEvent {
  const StoreEvent(this.productId, this.kind);

  final String productId;
  final StoreEventKind kind;
}

/// The calls the service needs from the store.
abstract class StoreDriver {
  Future<bool> isAvailable();

  /// Localised price text, or null when the store has no such product.
  Future<String?> priceText(String productId);

  /// Starts the purchase flow. False when it could not start.
  Future<bool> buy(String productId);

  Future<void> restore();

  Stream<StoreEvent> get events;
}

class GoogleStoreDriver implements StoreDriver {
  GoogleStoreDriver({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  ProductDetails? _product;

  Future<ProductDetails?> _query(String id) async {
    final ProductDetails? cached = _product;
    if (cached != null && cached.id == id) {
      return cached;
    }
    final ProductDetailsResponse r = await _iap.queryProductDetails(<String>{id});
    return _product = r.productDetails.isEmpty ? null : r.productDetails.first;
  }

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<String?> priceText(String productId) async => (await _query(productId))?.price;

  @override
  Future<bool> buy(String productId) async {
    final ProductDetails? product = await _query(productId);
    if (product == null) {
      return false;
    }
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Stream<StoreEvent> get events => _iap.purchaseStream.expand((List<PurchaseDetails> list) {
        return list.map((PurchaseDetails d) {
          if (d.pendingCompletePurchase) {
            _iap.completePurchase(d);
          }
          final StoreEventKind kind = switch (d.status) {
            PurchaseStatus.purchased => StoreEventKind.purchased,
            PurchaseStatus.restored => StoreEventKind.restored,
            PurchaseStatus.pending => StoreEventKind.pending,
            PurchaseStatus.canceled => StoreEventKind.canceled,
            PurchaseStatus.error => StoreEventKind.error,
          };
          return StoreEvent(d.productID, kind);
        });
      });
}

/// Remove Ads. With no backend the entitlement comes from the store's own
/// purchase state: restore is asked at launch, and the last known answer is
/// cached so an offline launch does not show ads to someone who paid.
class BillingService implements BillingPort {
  BillingService({
    required this.driver,
    required this.productId,
    this.storage,
    this.log,
    this.settleTimeout = const Duration(seconds: 5),
    this.purchaseTimeout = const Duration(minutes: 2),
  });

  static const String cacheKey = 'entitlement';

  final StoreDriver driver;
  final String productId;
  final StoragePort? storage;
  final LogPort? log;

  /// How long to wait for the store to report an owned purchase after a restore.
  final Duration settleTimeout;

  /// How long a purchase flow may take before it is reported as pending.
  final Duration purchaseTimeout;

  final StreamController<Entitlement> _changes = StreamController<Entitlement>.broadcast();
  StreamSubscription<StoreEvent>? _subscription;
  Entitlement _entitlement = Entitlement.unknown;
  Completer<PurchaseOutcome>? _waiter;
  Completer<void>? _ownedSignal;

  /// Reads the cached answer, starts listening and asks the store to restore.
  /// Returns quickly; the answer arrives through [entitlementChanges].
  Future<void> start() async {
    try {
      if (await storage?.readString(cacheKey) == 'adsRemoved') {
        _entitlement = Entitlement.adsRemoved;
      }
    } on Object {
      // No cache is fine.
    }
    _listen();
    unawaited(_settle());
  }

  void _listen() {
    _subscription ??= driver.events.listen(_onEvent, onError: (Object e) {
      log?.log(LogLevel.warning, 'Store event failed', error: e);
    });
  }

  Future<void> _settle() async {
    try {
      if (!await driver.isAvailable()) {
        return;
      }
      final bool owned = await _restoreAndWait();
      // The store said nothing: keep a cached answer rather than punish a flaky connection.
      if (!owned && _entitlement != Entitlement.adsRemoved) {
        _set(Entitlement.none);
      }
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Could not read purchases', error: e);
    }
  }

  Future<bool> _restoreAndWait() async {
    _listen();
    final Completer<void> signal = Completer<void>();
    _ownedSignal = signal;
    await driver.restore();
    await signal.future.timeout(settleTimeout, onTimeout: () {});
    _ownedSignal = null;
    return _entitlement == Entitlement.adsRemoved && signal.isCompleted;
  }

  void _set(Entitlement e) {
    if (_entitlement == e) {
      return;
    }
    _entitlement = e;
    _changes.add(e);
    final StoragePort? s = storage;
    if (s != null && e != Entitlement.unknown) {
      s.writeString(cacheKey, e == Entitlement.adsRemoved ? 'adsRemoved' : 'none').catchError((Object _) {});
    }
  }

  void _onEvent(StoreEvent e) {
    if (e.productId != productId) {
      return;
    }
    switch (e.kind) {
      case StoreEventKind.purchased:
        _set(Entitlement.adsRemoved);
        _ownedSignal?.complete();
        _finish(PurchaseOutcome.purchased);
      case StoreEventKind.restored:
        _set(Entitlement.adsRemoved);
        _ownedSignal?.complete();
        _finish(PurchaseOutcome.restored);
      case StoreEventKind.pending:
        _finish(PurchaseOutcome.pending);
      case StoreEventKind.canceled:
        _finish(PurchaseOutcome.cancelled);
      case StoreEventKind.error:
        _finish(PurchaseOutcome.failed);
    }
  }

  void _finish(PurchaseOutcome outcome) {
    final Completer<PurchaseOutcome>? w = _waiter;
    if (w != null && !w.isCompleted) {
      w.complete(outcome);
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await driver.isAvailable();
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> priceText() async {
    try {
      return await driver.priceText(productId);
    } on Object {
      return null;
    }
  }

  @override
  Future<Entitlement> currentEntitlement() async => _entitlement;

  @override
  Future<PurchaseOutcome> buy() async {
    if (_entitlement == Entitlement.adsRemoved) {
      return PurchaseOutcome.restored;
    }
    _listen();
    final Completer<PurchaseOutcome> waiter = Completer<PurchaseOutcome>();
    _waiter = waiter;
    try {
      if (!await driver.isAvailable() || !await driver.buy(productId)) {
        return PurchaseOutcome.failed;
      }
      return await waiter.future.timeout(purchaseTimeout, onTimeout: () => PurchaseOutcome.pending);
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Purchase failed', error: e);
      return PurchaseOutcome.failed;
    } finally {
      _waiter = null;
    }
  }

  @override
  Future<PurchaseOutcome> restore() async {
    try {
      if (!await driver.isAvailable()) {
        return PurchaseOutcome.failed;
      }
      final bool owned = await _restoreAndWait();
      if (owned) {
        return PurchaseOutcome.restored;
      }
      _set(Entitlement.none);
      return PurchaseOutcome.nothingToRestore;
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Restore failed', error: e);
      return PurchaseOutcome.failed;
    }
  }

  @override
  Stream<Entitlement> get entitlementChanges => _changes.stream;

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _changes.close();
  }
}
