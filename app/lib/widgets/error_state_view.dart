import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'primary_button.dart';

/// The full-screen fallback for an unexpected error: a plain message, Retry,
/// and an optional link to email a report. It never shows a stack trace.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.reportLabel,
    this.onReport,
  }) : assert((reportLabel == null) == (onReport == null), 'A report link needs both a label and a handler');

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? reportLabel;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(child: AppIcon(AppIcons.error, size: IconSizes.xl, color: theme.palette.error)),
                  const SizedBox(height: Sp.md),
                  Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: theme.text.headline)),
                  const SizedBox(height: Sp.sm),
                  Text(message, textAlign: TextAlign.center, style: theme.text.body.copyWith(color: theme.palette.textSecondary)),
                  const SizedBox(height: Sp.lg),
                  PrimaryButton(label: retryLabel, icon: AppIcons.retry, onPressed: onRetry),
                  if (onReport != null)
                    Pressable(
                      onPressed: onReport,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                          child: Text(reportLabel!, style: theme.text.callout.copyWith(color: theme.palette.accent)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
