import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Uppercase, letter-spaced group title in the tertiary text colour.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: Sp.md, bottom: Sp.sm),
        child: Text(
          label.toUpperCase(),
          style: theme.text.caption.copyWith(color: theme.palette.textTertiary, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
