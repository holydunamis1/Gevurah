import 'package:flutter/widgets.dart';

import '../core/catalog/training_lessons.dart';
import '../core/models/fight_config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_scope.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_row.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import 'parts/app_ad_slot.dart';

/// Training: six short guided lessons in order, free practice against any
/// struggle, and How to play. No stars, no progress, no pressure.
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key, required this.onLesson, required this.onPractice, required this.onHowToPlay, required this.onBack});

  final ValueChanged<TrainingLesson> onLesson;
  final VoidCallback onPractice;
  final VoidCallback onHowToPlay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    final SettingsProvider settings = AppScope.of(context).settings;
    return ScreenFrame(
      navBar: NavBar(title: l.modeName(FightMode.training), onBack: onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: settings,
        builder: (BuildContext context, Widget? _) {
          final List<String> done = settings.settings.trainingDone;
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              Text(l.modeDescription(FightMode.training), style: theme.text.body),
              const SizedBox(height: Sp.lg),
              AppRow(label: l.howToOpen, leadingIcon: AppIcons.help, onPressed: onHowToPlay),
              SectionHeader(l.trainingLessons),
              for (final TrainingLesson lesson in TrainingLessons.all)
                AppRow(
                  label: l.lessonTitle(lesson.id),
                  leadingIcon: AppIcons.training,
                  value: done.contains(lesson.id) ? l.lessonDoneLabel : null,
                  onPressed: () => onLesson(lesson),
                ),
              SectionHeader(l.trainingPractice),
              AppRow(label: l.trainingPracticeRow, leadingIcon: AppIcons.fight, onPressed: onPractice),
            ],
          );
        },
      ),
    );
  }
}
