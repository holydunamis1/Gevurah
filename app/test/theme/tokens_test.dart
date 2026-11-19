import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/theme/tokens.dart';

double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final Map<String, AppPalette> themes = <String, AppPalette>{
    'light': AppPalette.light,
    'dark': AppPalette.dark,
  };

  for (final MapEntry<String, AppPalette> entry in themes.entries) {
    final AppPalette p = entry.value;
    final String name = entry.key;

    group('$name palette', () {
      test('text tokens reach 4.5:1 on every surface', () {
        final Map<String, Color> text = <String, Color>{
          'textPrimary': p.textPrimary,
          'textSecondary': p.textSecondary,
          'textTertiary': p.textTertiary,
        };
        final Map<String, Color> surfaces = <String, Color>{
          'bgPrimary': p.bgPrimary,
          'bgSecondary': p.bgSecondary,
          'bgTertiary': p.bgTertiary,
          'verseCardSurface': p.verseCardSurface,
        };
        for (final MapEntry<String, Color> t in text.entries) {
          for (final MapEntry<String, Color> s in surfaces.entries) {
            expect(
              contrast(t.value, s.value),
              greaterThanOrEqualTo(4.5),
              reason: '${t.key} on ${s.key} ($name)',
            );
          }
        }
      });

      test('accent and status text reach 4.5:1 on primary and secondary surfaces', () {
        final Map<String, Color> colours = <String, Color>{
          'accent': p.accent,
          'error': p.error,
          'success': p.success,
          'warning': p.warning,
        };
        for (final MapEntry<String, Color> c in colours.entries) {
          expect(contrast(c.value, p.bgPrimary), greaterThanOrEqualTo(4.5), reason: '${c.key} on bgPrimary ($name)');
          expect(contrast(c.value, p.bgSecondary), greaterThanOrEqualTo(4.5), reason: '${c.key} on bgSecondary ($name)');
        }
      });

      test('label on a filled accent surface reaches 4.5:1', () {
        expect(contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
      });

      test('meter and tell colours reach 3:1 as graphical objects', () {
        final Map<String, Color> graphics = <String, Color>{
          'resolveFill': p.resolveFill,
          'staminaFill': p.staminaFill,
          'weightFill': p.weightFill,
          'tellGlow': p.tellGlow,
        };
        for (final MapEntry<String, Color> g in graphics.entries) {
          expect(contrast(g.value, p.bgPrimary), greaterThanOrEqualTo(3.0), reason: '${g.key} on bgPrimary ($name)');
          expect(contrast(g.value, p.bgSecondary), greaterThanOrEqualTo(3.0), reason: '${g.key} on bgSecondary ($name)');
        }
      });
    });
  }

  test('accent text is not placed on the tertiary fill in the light theme', () {
    // Documented limit: light accent is below 4.5:1 on bgTertiary, so widgets
    // must not draw accent text on tertiary fills.
    expect(contrast(AppPalette.light.accent, AppPalette.light.bgTertiary), lessThan(4.5));
  });
}
