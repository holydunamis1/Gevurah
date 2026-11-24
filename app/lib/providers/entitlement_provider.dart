import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/ports/billing_port.dart';

enum EntitlementActivity { idle, purchasing, restoring }

class EntitlementState {
  const EntitlementState({
    this.entitlement = Entitlement.unknown,
    this.activity = EntitlementActivity.idle,
    this.priceText,
    this.storeAvailable = false,
    this.lastOutcome,
  });

  final Entitlement entitlement;
  final EntitlementActivity activity;
  final String? priceText;
  final bool storeAvailable;

  /// The result of the last purchase or restore, for the screen to report.
  final PurchaseOutcome? lastOutcome;

  /// The single answer every ad decision reads. Unknown counts as not removed.
  bool get adsRemoved => entitlement == Entitlement.adsRemoved;

  EntitlementState copyWith({
    Entitlement? entitlement,
    EntitlementActivity? activity,
    String? priceText,
    bool? storeAvailable,
    PurchaseOutcome? lastOutcome,
    bool clearOutcome = false,
  }) =>
      EntitlementState(
        entitlement: entitlement ?? this.entitlement,
        activity: activity ?? this.activity,
        priceText: priceText ?? this.priceText,
        storeAvailable: storeAvailable ?? this.storeAvailable,
        lastOutcome: clearOutcome ? null : (lastOutcome ?? this.lastOutcome),
      );

  @override
  bool operator ==(Object other) =>
      other is EntitlementState &&
      other.entitlement == entitlement &&
      other.activity == activity &&
      other.priceText == priceText &&
      other.storeAvailable == storeAvailable &&
      other.lastOutcome == lastOutcome;

  @override
  int get hashCode => Object.hash(entitlement, activity, priceText, storeAvailable, lastOutcome);
}

/// Whether ads are removed, and the purchase and restore actions. Ad decisions
/// read [EntitlementState.adsRemoved] and never infer it themselves.
class EntitlementProvider extends ValueNotifier<EntitlementState> {
  EntitlementProvider(this._billing) : super(const EntitlementState());

  final BillingPort _billing;
  StreamSubscription<Entitlement>? _subscription;

  bool get adsRemoved => value.adsRemoved;

  Future<void> start() async {
    _subscription ??= _billing.entitlementChanges.listen((Entitlement e) {
      value = value.copyWith(entitlement: e);
    });
    final bool available = await _billing.isAvailable();
    final String? price = available ? await _billing.priceText() : null;
    value = value.copyWith(
      entitlement: await _billing.currentEntitlement(),
      storeAvailable: available,
      priceText: price,
    );
  }

  /// Clears the message about the last purchase or restore.
  void dismissOutcome() => value = value.copyWith(clearOutcome: true);

  Future<PurchaseOutcome> buy() async {
    if (value.activity != EntitlementActivity.idle) {
      return PurchaseOutcome.pending;
    }
    value = value.copyWith(activity: EntitlementActivity.purchasing, clearOutcome: true);
    final PurchaseOutcome outcome = await _billing.buy();
    return _finish(outcome);
  }

  Future<PurchaseOutcome> restore() async {
    if (value.activity != EntitlementActivity.idle) {
      return PurchaseOutcome.pending;
    }
    value = value.copyWith(activity: EntitlementActivity.restoring, clearOutcome: true);
    final PurchaseOutcome outcome = await _billing.restore();
    return _finish(outcome);
  }

  Future<PurchaseOutcome> _finish(PurchaseOutcome outcome) async {
    final Entitlement now = await _billing.currentEntitlement();
    value = value.copyWith(entitlement: now, activity: EntitlementActivity.idle, lastOutcome: outcome);
    return outcome;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
