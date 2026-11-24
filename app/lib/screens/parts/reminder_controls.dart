import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/app_scope.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/icon_aliases.dart';
import '../../theme/tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_row.dart';
import '../../widgets/bottom_sheet.dart';
import '../../widgets/toggle_row.dart';
import '../../widgets/warning_banner.dart';

/// The opt-in daily reminder: a switch, the time once it is on, and a plain
/// message if notification permission was refused. Used by the Daily Bout
/// screen and Settings.
class ReminderControls extends StatelessWidget {
  const ReminderControls({super.key});

  /// Hours offered for the reminder, on the hour.
  static const List<int> hours = <int>[6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

  Future<void> _pickTime(BuildContext context, AppLocalizations l, AppProviders app) async {
    final int? minute = await showAppBottomSheet<int>(
      context,
      barrierLabel: l.commonClose,
      builder: (BuildContext sheet) => AppBottomSheet(
        title: l.reminderTime,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final int h in hours) AppRow(label: formatMinuteOfDay(h * 60), onPressed: () => Navigator.of(sheet).pop(h * 60)),
            ],
          ),
        ),
      ),
    );
    if (minute != null) {
      await app.reminder.setTime(minute, title: l.reminderTitle, body: l.reminderBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[app.settings, app.reminder]),
      builder: (BuildContext context, Widget? _) {
        final bool on = app.settings.settings.remindersOn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (app.reminder.value == ReminderStatus.permissionDenied) ...<Widget>[
              WarningBanner(message: l.reminderDenied),
              const SizedBox(height: Sp.md),
            ],
            ToggleRow(
              label: l.reminderToggle,
              icon: AppIcons.notifications,
              value: on,
              onChanged: (bool v) => unawaited(app.reminder.setEnabled(v, title: l.reminderTitle, body: l.reminderBody)),
            ),
            if (on)
              AppRow(
                label: l.reminderTime,
                leadingIcon: AppIcons.timing,
                value: formatMinuteOfDay(app.settings.settings.reminderMinuteOfDay),
                onPressed: () => unawaited(_pickTime(context, l, app)),
              ),
          ],
        );
      },
    );
  }
}
