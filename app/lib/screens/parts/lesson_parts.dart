import 'package:flutter/widgets.dart';

import '../../core/catalog/training_lessons.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../theme/app_theme.dart';
import '../../theme/icon_aliases.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_row.dart';
import '../../widgets/primary_button.dart';

/// A Training lesson being fought: the lesson, and what the player can do when
/// it ends. [onNext] is null after the last lesson.
class LessonRun {
  const LessonRun({required this.lesson, required this.onNext, required this.onRepeat, required this.onExit});

  final TrainingLesson lesson;
  final VoidCallback? onNext;
  final VoidCallback onRepeat;
  final VoidCallback onExit;
}

/// The goal and the count so far, drawn over the ring. It never takes touches,
/// so the player's taps and swipes reach the fight.
class LessonCoach extends StatelessWidget {
  const LessonCoach({super.key, required this.lesson, required this.done});

  final TrainingLesson lesson;
  final int done;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    return IgnorePointer(
      child: Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Sp.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.palette.bgSecondary,
              borderRadius: BorderRadius.circular(Radii.chip),
              border: Border.all(color: theme.palette.hairline, width: Strokes.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${l.lessonGoal(lesson)}  ${l.lessonProgress(done, lesson.target)}',
                  textAlign: TextAlign.center,
                  style: theme.text.footnote.copyWith(color: theme.palette.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the goal is met, or when the bout ended before it was.
class LessonOverlay extends StatelessWidget {
  const LessonOverlay({super.key, required this.run, required this.met});

  final LessonRun run;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    final VoidCallback? next = met ? run.onNext : null;
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sp.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(met ? l.lessonComplete : l.lessonNotYet, style: theme.text.title1, textAlign: TextAlign.center),
                const SizedBox(height: Sp.xs),
                Text(l.lessonGoal(run.lesson), style: theme.text.body, textAlign: TextAlign.center),
                const SizedBox(height: Sp.lg),
                if (next != null) ...<Widget>[
                  PrimaryButton(label: l.lessonNext, icon: AppIcons.forward, onPressed: next),
                  const SizedBox(height: Sp.sm),
                  AppRow(label: l.lessonRepeat, leadingIcon: AppIcons.retry, showChevron: false, onPressed: run.onRepeat),
                ] else
                  PrimaryButton(label: l.lessonRepeat, icon: AppIcons.retry, onPressed: run.onRepeat),
                AppRow(label: l.lessonBackToLessons, leadingIcon: AppIcons.back, showChevron: false, onPressed: run.onExit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
