/// Whether ads are removed.
enum Entitlement { unknown, adsRemoved, none }

enum PurchaseOutcome { purchased, restored, cancelled, pending, nothingToRestore, failed }

/// The one product: a one-time Remove Ads purchase.
abstract class BillingPort {
  Future<bool> isAvailable();

  /// Localised price text, or null when the store has no product.
  Future<String?> priceText();

  /// What the store says the player owns right now.
  Future<Entitlement> currentEntitlement();

  Future<PurchaseOutcome> buy();

  Future<PurchaseOutcome> restore();

  /// Emits when ownership changes outside a call (a pending purchase clears, a refund).
  Stream<Entitlement> get entitlementChanges;
}
