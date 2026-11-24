import 'dart:async';

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/entitlement_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_row.dart';
import '../widgets/entitlement_badge.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import 'parts/purchase_feedback.dart';

/// What Remove Ads does, with Buy and Restore. An optional path from Settings,
/// never a blocking screen, and with no ad of its own.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.upgradeTitle, onBack: onBack, backLabel: l.commonBack),
      child: ListenableBuilder(
        listenable: app.entitlement,
        builder: (BuildContext context, Widget? _) {
          final EntitlementState e = app.entitlement.value;
          final bool busy = e.activity != EntitlementActivity.idle;
          final String? price = e.priceText;
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              const PurchaseFeedback(),
              Text(l.upgradeBody, style: theme.text.body),
              const SizedBox(height: Sp.lg),
              if (e.adsRemoved) ...<Widget>[
                EntitlementBadge(adsRemoved: true, label: l.settingsAdsRemoved),
                const SizedBox(height: Sp.sm),
                Text(l.upgradeOwned, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              ] else ...<Widget>[
                PrimaryButton(
                  label: price == null ? l.upgradeBuyNoPrice : l.upgradeBuy(price),
                  icon: AppIcons.removeAds,
                  onPressed: e.storeAvailable && !busy ? () => unawaited(app.entitlement.buy()) : null,
                ),
                if (!e.storeAvailable) ...<Widget>[
                  const SizedBox(height: Sp.sm),
                  Text(l.upgradeUnavailable, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
                ],
              ],
              const SizedBox(height: Sp.lg),
              AppRow(
                label: l.settingsRestore,
                leadingIcon: AppIcons.retry,
                showChevron: false,
                onPressed: busy ? null : () => unawaited(app.entitlement.restore()),
              ),
            ],
          );
        },
      ),
    );
  }
}
