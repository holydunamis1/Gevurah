import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_scope.dart';
import '../../providers/rewards_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_row.dart';

/// One opt-in rewarded-ad offer: a row marked "Ad", hidden when no ad is ready
/// (or ads are off). Tapping runs [run]; [onEarned] fires only when the reward
/// was earned. A closed or failed ad grants nothing and shows a short line.
class RewardOffer extends StatefulWidget {
  const RewardOffer({super.key, required this.label, required this.icon, required this.run, this.onEarned, this.enabled = true, this.doneLabel});

  final String label;
  final IconData icon;

  /// Shows the ad and reports how it ended (often `rewards.watch`).
  final Future<RewardResult> Function() run;
  final VoidCallback? onEarned;

  /// False hides the offer (nothing to reward right now).
  final bool enabled;

  /// A line shown in place of the row once the reward was earned.
  final String? doneLabel;

  @override
  State<RewardOffer> createState() => _RewardOfferState();
}

class _RewardOfferState extends State<RewardOffer> {
  bool _working = false;
  RewardResult? _last;
  bool _earned = false;

  Future<void> _tap() async {
    if (_working) {
      return;
    }
    setState(() {
      _working = true;
      _last = null;
    });
    RewardResult result = RewardResult.notEarned;
    try {
      result = await widget.run();
    } on Object {
      result = RewardResult.notEarned;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _working = false;
      _last = result == RewardResult.earned ? null : result;
      _earned = result == RewardResult.earned;
    });
    if (result == RewardResult.earned) {
      widget.onEarned?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    final RewardsProvider rewards = AppScope.of(context).rewards;
    if (_earned && widget.doneLabel != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
        child: Text(widget.doneLabel!, style: theme.text.callout),
      );
    }
    if (!widget.enabled || (!rewards.offered && _last == null && !_working)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppRow(label: widget.label, leadingIcon: widget.icon, value: l.rewardAdTag, showChevron: false, onPressed: _working ? null : _tap),
        if (_last != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.sm),
            child: Text(
              _last == RewardResult.unavailable ? l.rewardUnavailable : l.rewardNotEarned,
              style: theme.text.footnote.copyWith(color: theme.palette.textSecondary),
            ),
          ),
      ],
    );
  }
}
