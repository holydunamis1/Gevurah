import 'package:flutter/widgets.dart';

/// Spacing scale. Widgets never contain a raw spacing value.
abstract final class Sp {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Corner radii.
abstract final class Radii {
  static const double card = 16;
  static const double hero = 24;
  static const double chip = 12;
  static const double button = 12;
  static const double sheet = 20;
  static const double dialog = 16;
}

/// Icon sizes. The minimum touch target is [target].
abstract final class IconSizes {
  static const double small = 16;
  static const double medium = 20;
  static const double large = 24;
  static const double xl = 32;
  static const double chip = 40;
  static const double target = 48;
}

/// Hairline border width. No shadows anywhere: separation is by fill and hairline.
abstract final class Strokes {
  static const double hairline = 1;
}

/// Every colour token, for one theme. Light and dark are constants so a theme
/// change is detected by identity.
@immutable
class AppPalette {
  const AppPalette({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.error,
    required this.success,
    required this.warning,
    required this.hairline,
    required this.resolveFill,
    required this.staminaFill,
    required this.weightFill,
    required this.tellGlow,
    required this.shadowTint,
    required this.verseCardSurface,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color accent;

  /// Label colour on a filled accent surface.
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color error;
  final Color success;
  final Color warning;
  final Color hairline;

  /// Player Resolve bar.
  final Color resolveFill;

  /// Player Stamina bar.
  final Color staminaFill;

  /// Struggle Weight bar.
  final Color weightFill;

  /// Glow around a struggle's telegraph. Never the only signal of a tell.
  final Color tellGlow;

  /// Body tint of the shadow forms.
  final Color shadowTint;
  final Color verseCardSurface;

  static const AppPalette light = AppPalette(
    bgPrimary: Color(0xFFF4F2EE),
    bgSecondary: Color(0xFFFFFFFF),
    bgTertiary: Color(0xFFEBE7E0),
    accent: Color(0xFFB04A12),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF14120F),
    textSecondary: Color(0xFF5C564D),
    textTertiary: Color(0xFF655E54),
    error: Color(0xFFB3261E),
    success: Color(0xFF1B6B3A),
    warning: Color(0xFF8A5A00),
    hairline: Color(0x1F14120F),
    resolveFill: Color(0xFF1B6B3A),
    staminaFill: Color(0xFF1F5E99),
    weightFill: Color(0xFFB3261E),
    tellGlow: Color(0xFFB04A12),
    shadowTint: Color(0xFF3A3340),
    verseCardSurface: Color(0xFFFBF8F2),
  );

  static const AppPalette dark = AppPalette(
    bgPrimary: Color(0xFF0E0D12),
    bgSecondary: Color(0xFF1B1A22),
    bgTertiary: Color(0xFF28262F),
    accent: Color(0xFFF2924A),
    onAccent: Color(0xFF1A0C03),
    textPrimary: Color(0xFFF6F3EE),
    textSecondary: Color(0xFFB8B2A8),
    textTertiary: Color(0xFFA29B90),
    error: Color(0xFFFF7B72),
    success: Color(0xFF4CD08A),
    warning: Color(0xFFF5B94A),
    hairline: Color(0x24F6F3EE),
    resolveFill: Color(0xFF4CD08A),
    staminaFill: Color(0xFF6CB4F5),
    weightFill: Color(0xFFFF7B72),
    tellGlow: Color(0xFFF2924A),
    shadowTint: Color(0xFF8F8899),
    verseCardSurface: Color(0xFF23212B),
  );
}
