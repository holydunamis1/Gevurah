import 'package:flutter/widgets.dart';

import '../../core/ports/billing_port.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../providers/app_providers.dart';
import '../../providers/app_scope.dart';
import '../../theme/tokens.dart';
import '../../widgets/feedback_banner.dart';

/// Reports the result of the last purchase or restore, and can be dismissed.
/// Every purchase action gets a visible result.
class PurchaseFeedback extends StatelessWidget {
  const PurchaseFeedback({super.key});

  static FeedbackKind kindFor(PurchaseOutcome outcome) {
    switch (outcome) {
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        return FeedbackKind.success;
      case PurchaseOutcome.failed:
        return FeedbackKind.failure;
      case PurchaseOutcome.cancelled:
      case PurchaseOutcome.pending:
      case PurchaseOutcome.nothingToRestore:
        return FeedbackKind.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.entitlement,
      builder: (BuildContext context, Widget? _) {
        final PurchaseOutcome? outcome = app.entitlement.value.lastOutcome;
        if (outcome == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Sp.md),
          child: FeedbackBanner(
            kind: kindFor(outcome),
            message: l.purchaseMessage(outcome),
            onDismiss: app.entitlement.dismissOutcome,
            dismissLabel: l.commonDismiss,
          ),
        );
      },
    );
  }
}
