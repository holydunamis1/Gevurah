import 'package:flutter/widgets.dart';

import '../../core/models/verse.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../providers/app_scope.dart';
import '../../providers/verse_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/verse_card.dart';

/// A verse with an optional caption (for example the struggle it belongs to).
class LabeledVerse {
  const LabeledVerse(this.verse, {this.label});

  final Verse verse;
  final String? label;
}

/// A list of verse cards loaded together. It reloads when the language changes
/// and shows nothing for an empty list; [empty] is shown instead when given.
class VerseList extends StatefulWidget {
  const VerseList({super.key, required this.load, this.empty});

  final Future<List<LabeledVerse>> Function(VerseProvider verses) load;
  final String? empty;

  @override
  State<VerseList> createState() => _VerseListState();
}

class _VerseListState extends State<VerseList> {
  Future<List<LabeledVerse>>? _future;
  String? _language;

  @override
  Widget build(BuildContext context) {
    final VerseProvider verses = AppScope.of(context).verses;
    final AppTheme theme = AppTheme.of(context);
    return ListenableBuilder(
      listenable: verses,
      builder: (BuildContext context, Widget? _) {
        if (_future == null || _language != verses.value) {
          _language = verses.value;
          _future = widget.load(verses);
        }
        return FutureBuilder<List<LabeledVerse>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<LabeledVerse>> snapshot) {
            final List<LabeledVerse> items = snapshot.data ?? const <LabeledVerse>[];
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            if (items.isEmpty) {
              final String? text = widget.empty;
              return text == null ? const SizedBox.shrink() : Text(text, style: theme.text.callout.copyWith(color: theme.palette.textSecondary));
            }
            final AppLocalizations l = AppLocalizations.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final LabeledVerse item in items) ...<Widget>[
                  if (item.label != null) ...<Widget>[
                    Text(item.label!, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
                    const SizedBox(height: Sp.xs),
                  ],
                  VerseCard(text: item.verse.text, reference: l.reference(item.verse.ref), translation: item.verse.translationId),
                  const SizedBox(height: Sp.md),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
