/// The current time, so the Daily Bout and reminders can be tested.
abstract class ClockPort {
  /// The player's local date and time.
  DateTime now();
}

/// The real clock.
class SystemClock implements ClockPort {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
