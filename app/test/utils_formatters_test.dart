import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/utils/formatters.dart';

void main() {
  test('formatNumber groups digits for English', () {
    expect(formatNumber(1234567, 'en'), '1,234,567');
  });

  test('formatPercent renders a fraction as a percentage', () {
    expect(formatPercent(0.5, 'en'), '50%');
  });

  test('formatClock pads seconds and keeps Latin digits', () {
    expect(formatClock(const Duration(seconds: 65)), '1:05');
    expect(formatClock(const Duration(seconds: 0)), '0:00');
    expect(formatClock(const Duration(seconds: -3)), '0:00');
    expect(formatClock(const Duration(seconds: 60)), '1:00');
  });
}
