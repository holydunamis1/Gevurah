import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Icon, title and optional subtitle, centred. For lists with nothing yet.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(icon, size: IconSizes.xl, color: theme.palette.textTertiary),
            const SizedBox(height: Sp.md),
            Text(title, textAlign: TextAlign.center, style: theme.text.title2),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: Sp.xs),
              Text(subtitle!, textAlign: TextAlign.center, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
