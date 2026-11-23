import 'package:flutter/widgets.dart';

import '../core/models/curated_verse.dart';
import '../core/models/stance.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_control.dart';
import 'parts/verse_block.dart';

/// The corner between rounds: a verse, a word that Stamina is restored, a
/// choice of stance for the rest of the bout, and a button for the next round.
/// It fills the arena while the bout is paused, and sits side by side with the
/// verse when the arena is wide (landscape).
class CornerScreen extends StatelessWidget {
  const CornerScreen({super.key, required this.round, required this.stance, required this.onStance, required this.onNextRound});

  /// The round that just ended.
  final int round;

  /// The stance in force now.
  final Stance stance;
  final ValueChanged<Stance> onStance;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    final Widget verse = SingleChildScrollView(child: VerseBlock(load: (verses) => verses.forMoment(VerseMoment.corner, seed: round)));
    final Widget controls = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l.cornerStance, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
          const SizedBox(height: Sp.xs),
          SegmentedControl<Stance>(
            options: <SegmentOption<Stance>>[for (final Stance s in Stance.values) SegmentOption<Stance>(value: s, label: l.stanceName(s))],
            selected: stance,
            onChanged: onStance,
          ),
          const SizedBox(height: Sp.xs),
          Text(l.stanceHint(stance), style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
          const SizedBox(height: Sp.md),
          Text(l.cornerRested, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
          const SizedBox(height: Sp.sm),
          PrimaryButton(label: l.cornerNext, onPressed: onNextRound),
        ],
      ),
    );
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final Widget heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l.cornerTitle, style: theme.text.headline),
                const SizedBox(height: Sp.xs),
                Text(l.cornerRoundDone(round), style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              ],
            );
            if (box.maxWidth > box.maxHeight) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[heading, const SizedBox(height: Sp.md), Expanded(child: verse)],
                    ),
                  ),
                  const SizedBox(width: Sp.lg),
                  Expanded(child: Center(child: controls)),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[heading, const SizedBox(height: Sp.lg), Expanded(child: verse), const SizedBox(height: Sp.md), controls],
            );
          },
        ),
      ),
    );
  }
}
