import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state_view.dart';

/// The full-screen fallback when something unexpected fails. It offers Retry
/// and an email report. It reads only the theme and the localizations, so it
/// can stand on its own when the rest of the app has failed.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.onRetry, required this.onReport});

  final VoidCallback onRetry;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: SafeArea(
        child: ErrorStateView(
          title: l.errorTitle,
          message: l.errorMessage,
          retryLabel: l.errorRetry,
          onRetry: onRetry,
          reportLabel: l.errorReport,
          onReport: onReport,
        ),
      ),
    );
  }
}
