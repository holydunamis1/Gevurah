import 'package:flutter/widgets.dart';

import '../core/models/curated_verse.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/primary_button.dart';
import 'parts/verse_block.dart';

/// The corner between rounds: a verse, a word that Stamina is restored, and a
/// button for the next round. It fills the arena while the bout is paused.
class CornerScreen extends StatelessWidget {
  const CornerScreen({super.key, required this.round, required this.onNextRound});

  /// The round that just ended.
  final int round;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.cornerTitle, style: theme.text.headline),
            const SizedBox(height: Sp.xs),
            Text(l.cornerRoundDone(round), style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
            const SizedBox(height: Sp.lg),
            Expanded(
              child: SingleChildScrollView(
                child: VerseBlock(load: (verses) => verses.forMoment(VerseMoment.corner, seed: round)),
              ),
            ),
            Text(l.cornerRested, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
            const SizedBox(height: Sp.md),
            PrimaryButton(label: l.cornerNext, onPressed: onNextRound),
          ],
        ),
      ),
    );
  }
}
