/// One daily reminder, local only. The text is passed in already localised.
abstract class NotificationPort {
  Future<bool> permissionGranted();

  /// Asks for permission when the player turns reminders on. True if granted.
  Future<bool> requestPermission();

  /// Schedules (or replaces) the daily reminder at [minuteOfDay] local time.
  Future<void> scheduleDaily({required int minuteOfDay, required String title, required String body});

  Future<void> cancelDaily();
}
