import 'package:flutter/foundation.dart';

import '../core/ports/notification_port.dart';
import 'settings_provider.dart';

enum ReminderStatus { off, scheduled, permissionDenied }

/// The daily reminder. The text comes from the screen so it is in the
/// player's language. Turning it on asks for permission only then; a refusal
/// leaves it off and says so, and nothing else is affected.
class ReminderProvider extends ValueNotifier<ReminderStatus> {
  ReminderProvider({required NotificationPort notifications, required SettingsProvider settings})
      : _notifications = notifications,
        _settings = settings,
        super(ReminderStatus.off);

  final NotificationPort _notifications;
  final SettingsProvider _settings;

  /// Re-applies the saved setting, for launch and for a language change.
  Future<void> sync({required String title, required String body}) async {
    final bool on = _settings.settings.remindersOn;
    try {
      if (!on) {
        await _notifications.cancelDaily();
        value = ReminderStatus.off;
        return;
      }
      if (!await _notifications.permissionGranted()) {
        value = ReminderStatus.permissionDenied;
        return;
      }
      await _notifications.scheduleDaily(minuteOfDay: _settings.settings.reminderMinuteOfDay, title: title, body: body);
      value = ReminderStatus.scheduled;
    } on Object {
      value = ReminderStatus.off;
    }
  }

  Future<ReminderStatus> setEnabled(bool enabled, {required String title, required String body}) async {
    if (enabled) {
      bool granted = false;
      try {
        granted = await _notifications.permissionGranted() || await _notifications.requestPermission();
      } on Object {
        granted = false;
      }
      if (!granted) {
        await _settings.update((s) => s.copyWith(remindersOn: false));
        value = ReminderStatus.permissionDenied;
        return value;
      }
    }
    await _settings.update((s) => s.copyWith(remindersOn: enabled));
    await sync(title: title, body: body);
    return value;
  }

  Future<void> setTime(int minuteOfDay, {required String title, required String body}) async {
    await _settings.update((s) => s.copyWith(reminderMinuteOfDay: minuteOfDay.clamp(0, 1439)));
    await sync(title: title, body: body);
  }
}
