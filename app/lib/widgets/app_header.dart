import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'icon_chip.dart';

/// The one header every screen sits under: the wordmark at the start and the
/// few places a player may want at the end (Map, Daily Bout, Sound, Settings).
/// Uses start and end, so it mirrors in right-to-left.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.wordmark,
    required this.mapLabel,
    required this.dailyLabel,
    required this.soundLabel,
    required this.settingsLabel,
    required this.soundOn,
    required this.showDaily,
    required this.onMap,
    required this.onDaily,
    required this.onSound,
    required this.onSettings,
  });

  final String wordmark;
  final String mapLabel;
  final String dailyLabel;
  final String soundLabel;
  final String settingsLabel;
  final bool soundOn;
  final bool showDaily;
  final VoidCallback onMap;
  final VoidCallback onDaily;
  final VoidCallback onSound;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(wordmark, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.text.title2),
            ),
            IconChip(icon: AppIcons.journey, semanticLabel: mapLabel, onPressed: onMap),
            if (showDaily) IconChip(icon: AppIcons.daily, semanticLabel: dailyLabel, onPressed: onDaily),
            IconChip(icon: soundOn ? AppIcons.sound : AppIcons.muted, semanticLabel: soundLabel, onPressed: onSound),
            IconChip(icon: AppIcons.settings, semanticLabel: settingsLabel, onPressed: onSettings),
          ],
        ),
      ),
    );
  }
}
