import 'package:flutter/widgets.dart';

import '../core/catalog/card_catalog.dart';
import '../core/catalog/struggle_catalog.dart';
import '../core/logic/progression_rules.dart';
import '../core/models/daily_challenge.dart';
import '../core/models/fight_config.dart';
import '../core/models/loadout.dart';
import '../core/models/struggle_def.dart';
import '../core/models/verse_card_def.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_row.dart';
import '../widgets/nav_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import 'parts/app_ad_slot.dart';
import 'parts/verse_block.dart';

/// Who the player is about to face: its name, its tell, a verse, and the
/// equipped cards. Starting the bout configures the fight provider and then
/// calls [onStart].
class OpponentCardScreen extends StatelessWidget {
  const OpponentCardScreen({
    super.key,
    required this.struggleId,
    required this.mode,
    required this.onStart,
    required this.onChangeCards,
    required this.onBack,
    this.daily,
    this.difficulty = Difficulty.standard,
  });

  final String struggleId;
  final FightMode mode;
  final DailyChallenge? daily;
  final Difficulty difficulty;
  final VoidCallback onStart;
  final VoidCallback onChangeCards;
  final VoidCallback onBack;

  void _start(AppProviders app) {
    final Loadout loadout = app.loadout.value.loadout;
    final int seed = daily?.seed ?? app.fight.clock.now().millisecondsSinceEpoch & 0x7fffffff;
    final bool started = app.fight.start(
      FightConfig(
        mode: mode,
        struggleId: struggleId,
        cardIds: loadout.cardIds,
        stance: loadout.stance,
        seed: seed,
        difficulty: difficulty,
        timingAssist: app.settings.settings.timingAssist,
      ),
      daily: daily,
    );
    if (started) {
      onStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    final StruggleDef? def = StruggleCatalog.byId(struggleId);
    final String name = def == null ? struggleId : l.struggleName(struggleId);
    return ScreenFrame(
      navBar: NavBar(title: name, onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[app.loadout, app.progress]),
        builder: (BuildContext context, Widget? _) {
          final Loadout loadout = app.loadout.value.loadout;
          final bool canFight = def != null && ProgressionRules.canFight(app.progress.value.progress, mode, struggleId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Sp.lg),
                  children: <Widget>[
              if (def != null && def.track == StruggleTrack.career) Text(l.tierLabel(def.tier), style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
              if (def != null) ...<Widget>[
                const SizedBox(height: Sp.sm),
                Text(l.struggleTell(struggleId), style: theme.text.body),
              ],
              const SizedBox(height: Sp.lg),
              SectionHeader(l.opponentVerse),
              VerseBlock(load: (verses) => verses.preBout(struggleId)),
              SectionHeader(l.opponentCards),
              if (loadout.cardIds.isEmpty) Text(l.opponentNoCards, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              for (final String id in loadout.cardIds) _cardRow(l, id),
              AppRow(label: l.opponentStance(l.stanceName(loadout.stance)), leadingIcon: AppIcons.guard, showChevron: false),
              AppRow(label: l.opponentChange, onPressed: onChangeCards),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.lg),
                child: PrimaryButton(label: l.opponentStart, icon: AppIcons.fight, onPressed: canFight ? () => _start(app) : null),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardRow(AppLocalizations l, String id) {
    final VerseCardDef? c = CardCatalog.byId(id);
    if (c == null) {
      return const SizedBox.shrink();
    }
    return AppRow(label: l.cardTypeName(c.type), value: l.reference(c.ref), showChevron: false);
  }
}
