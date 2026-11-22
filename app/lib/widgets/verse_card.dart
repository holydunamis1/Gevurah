import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A verse and its reference on the scripture surface. Shown only in pauses.
/// The text is displayed exactly as given and is never shortened or restyled.
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.text, required this.reference, this.translation});

  final String text;

  /// The formatted reference, for example "Ephesians 6:13".
  final String reference;

  /// The translation name, shown small under the reference when given.
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    return Semantics(
      container: true,
      label: '$text $reference',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.verseCardSurface,
          borderRadius: BorderRadius.circular(Radii.hero),
          border: Border.all(color: theme.palette.hairline, width: Strokes.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(text, style: theme.text.body),
              const SizedBox(height: Sp.md),
              Text(reference, style: theme.text.callout.copyWith(color: theme.palette.accent)),
              if (translation != null) ...<Widget>[
                const SizedBox(height: Sp.xxs),
                Text(translation!, style: theme.text.caption.copyWith(color: theme.palette.textTertiary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
