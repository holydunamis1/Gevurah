import 'package:flutter/widgets.dart';

import '../core/catalog/card_catalog.dart';
import '../core/models/curated_verse.dart';
import '../core/models/fight_config.dart';
import '../core/models/verse_card_def.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/fight_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_row.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/star_row.dart';
import 'parts/app_ad_slot.dart';
import 'parts/reward_offer.dart';
import 'parts/verse_block.dart';

/// The end of a bout: the outcome, stars, a verse, any card or achievements
/// earned. Opening it records the bout once and, at this natural pause, offers
/// the ad provider a chance to show an interstitial.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.onContinue, required this.onTryAgain, required this.onHome, this.onRetry});

  final VoidCallback onContinue;
  final VoidCallback onTryAgain;
  final VoidCallback onHome;

  /// Called after a rewarded retry has started a fresh bout; the caller opens the fight.
  final VoidCallback? onRetry;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Future<FightFinish?>? _finish;

  Future<FightFinish?> _run(AppProviders app) async {
    final FightFinish? done = await app.fight.finish();
    if (done != null) {
      await app.ads.maybeShowInterstitial();
    }
    return done;
  }

  /// One earned retry after a loss, in the modes with a fresh seed. Never for
  /// the Daily Bout (same for everyone), Endurance or Training.
  bool _canRetry(FightFinish f, bool won) {
    final FightConfig c = f.view.config;
    final bool mode = c.mode == FightMode.journey || c.mode == FightMode.trials || c.mode == FightMode.sparring;
    return widget.onRetry != null && !won && mode && !c.isRetry;
  }

  void _retry(AppProviders app, FightConfig c) {
    final int seed = app.fight.clock.now().millisecondsSinceEpoch & 0x7fffffff;
    final bool started = app.fight.start(c.copyWith(seed: seed, isRetry: true, extraBreath: 0, extraStamina: 0));
    if (started) {
      widget.onRetry!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    final Future<FightFinish?> future = _finish ??= _run(app);
    return ScreenFrame(
      navBar: NavBar(title: l.appName),
      adSlot: const AppAdSlot(),
      child: FutureBuilder<FightFinish?>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<FightFinish?> snapshot) {
          final FightFinish? f = snapshot.data;
          if (f == null) {
            return const SizedBox.shrink();
          }
          final bool endurance = f.view.config.mode == FightMode.endurance;
          final bool won = endurance || f.view.won;
          final String? cardId = f.applied?.newCardId;
          final VerseCardDef? card = cardId == null ? null : CardCatalog.byId(cardId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Sp.lg),
                  children: <Widget>[
              Text(endurance ? l.enduranceResult(f.view.history.length) : (won ? l.resultWon : l.resultLost), style: theme.text.display),
              const SizedBox(height: Sp.sm),
              Text(l.struggleName(f.view.struggle.id), style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              const SizedBox(height: Sp.md),
              if (endurance && f.applied != null) ...<Widget>[
                Text(l.enduranceBest(f.applied!.after.enduranceBest), style: theme.text.title2),
                if (f.applied!.after.enduranceBest > f.applied!.before.enduranceBest) Text(l.enduranceNewBest, style: theme.text.callout),
              ] else if (won)
                StarRow(stars: f.view.stars, label: l.resultStars(f.view.stars)),
              const SizedBox(height: Sp.lg),
              VerseBlock(load: (verses) => verses.forMoment(won ? VerseMoment.win : VerseMoment.loss, seed: f.view.config.seed)),
              if (card != null) ...<Widget>[
                const SizedBox(height: Sp.lg),
                AppRow(label: l.resultCard, value: '${l.cardTypeName(card.type)} · ${l.reference(card.ref)}', showChevron: false),
              ],
              if (f.newAchievements.isNotEmpty) ...<Widget>[
                const SizedBox(height: Sp.sm),
                Text(l.resultAchievements(f.newAchievements.length), style: theme.text.callout),
              ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_canRetry(f, won)) RewardOffer(label: l.rewardRetry, icon: AppIcons.retry, run: app.rewards.watch, onEarned: () => _retry(app, f.view.config)),
                    PrimaryButton(label: l.resultContinue, onPressed: widget.onContinue),
                    AppRow(label: l.resultTryAgain, onPressed: widget.onTryAgain),
                    AppRow(label: l.resultHome, onPressed: widget.onHome),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
