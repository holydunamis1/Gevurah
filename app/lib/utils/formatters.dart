import 'package:intl/intl.dart';

/// Locale-aware display formatting. [locale] is a BCP 47 / intl locale name
/// such as `en`, `ar` or `pt_BR`.

String formatNumber(num value, String locale) {
  return NumberFormat.decimalPattern(locale).format(value);
}

/// [fraction] is 0.0 to 1.0.
String formatPercent(double fraction, String locale) {
  return NumberFormat.percentPattern(locale).format(fraction);
}

String formatDate(DateTime date, String locale) {
  return DateFormat.yMMMd(locale).format(date);
}

/// Formats a duration as m:ss, for example 1:05. Digits are always Latin so
/// the round clock stays readable in every language.
String formatClock(Duration duration) {
  final int totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// A minute of the day as HH:mm with Latin digits, for example 09:30.
String formatMinuteOfDay(int minuteOfDay) {
  final int m = minuteOfDay.clamp(0, 1439);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}
