import 'dart:ui' show FontVariation;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Bundled font families. Inter carries headers and interface chrome;
/// Source Sans 3 carries scripture and running text. Other scripts fall
/// back to the platform's system fonts.
abstract final class FontFamilies {
  static const String chrome = 'Inter';
  static const String scripture = 'SourceSans3';
}

/// The eight text roles. Sizes in logical pixels; height is a multiple of size.
@immutable
class TextRoles {
  const TextRoles._({
    required this.display,
    required this.headline,
    required this.title1,
    required this.title2,
    required this.body,
    required this.callout,
    required this.footnote,
    required this.caption,
  });

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title1;
  final TextStyle title2;

  /// Scripture and running text.
  final TextStyle body;

  /// Buttons and labels.
  final TextStyle callout;
  final TextStyle footnote;
  final TextStyle caption;

  static TextStyle _style({
    required String family,
    required double size,
    required FontWeight weight,
    required double height,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      fontVariations: <FontVariation>[FontVariation('wght', weight.value.toDouble())],
    );
  }

  factory TextRoles._build(AppPalette p) {
    return TextRoles._(
      display: _style(
        family: FontFamilies.chrome,
        size: 34,
        weight: FontWeight.w700,
        height: 1.1,
        color: p.textPrimary,
      ),
      headline: _style(
        family: FontFamilies.chrome,
        size: 28,
        weight: FontWeight.w600,
        height: 1.2,
        color: p.textPrimary,
      ),
      title1: _style(
        family: FontFamilies.chrome,
        size: 22,
        weight: FontWeight.w600,
        height: 1.3,
        color: p.textPrimary,
      ),
      title2: _style(
        family: FontFamilies.chrome,
        size: 17,
        weight: FontWeight.w600,
        height: 1.3,
        color: p.textPrimary,
      ),
      body: _style(
        family: FontFamilies.scripture,
        size: 17,
        weight: FontWeight.w400,
        height: 1.5,
        color: p.textPrimary,
      ),
      callout: _style(
        family: FontFamilies.chrome,
        size: 16,
        weight: FontWeight.w500,
        height: 1.4,
        color: p.textPrimary,
      ),
      footnote: _style(
        family: FontFamilies.chrome,
        size: 13,
        weight: FontWeight.w400,
        height: 1.4,
        color: p.textSecondary,
      ),
      caption: _style(
        family: FontFamilies.chrome,
        size: 12,
        weight: FontWeight.w400,
        height: 1.3,
        color: p.textTertiary,
      ),
    );
  }

  static final TextRoles light = TextRoles._build(AppPalette.light);
  static final TextRoles dark = TextRoles._build(AppPalette.dark);
}
