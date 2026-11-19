import 'package:flutter/widgets.dart';

import 'tokens.dart';
import 'typography.dart';

/// Gives widgets the palette and text roles without Material.
class AppTheme extends InheritedWidget {
  const AppTheme({
    super.key,
    required this.palette,
    required this.text,
    required super.child,
  });

  /// The theme for a brightness, using the shared constant palettes.
  factory AppTheme.forBrightness({
    Key? key,
    required Brightness brightness,
    required Widget child,
  }) {
    final bool isDark = brightness == Brightness.dark;
    return AppTheme(
      key: key,
      palette: isDark ? AppPalette.dark : AppPalette.light,
      text: isDark ? TextRoles.dark : TextRoles.light,
      child: child,
    );
  }

  final AppPalette palette;
  final TextRoles text;

  static AppTheme of(BuildContext context) {
    final AppTheme? theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(theme != null, 'No AppTheme found above this context.');
    return theme!;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return !identical(palette, oldWidget.palette) || !identical(text, oldWidget.text);
  }
}
