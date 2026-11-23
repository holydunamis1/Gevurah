import 'package:flutter/widgets.dart';

import '../../core/models/verse.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../providers/app_scope.dart';
import '../../providers/verse_provider.dart';
import '../../widgets/verse_card.dart';

/// A verse in the player's language. Nothing shows while it loads or when none
/// is found; it reloads when the language changes.
class VerseBlock extends StatefulWidget {
  const VerseBlock({super.key, required this.load});

  final Future<Verse?> Function(VerseProvider verses) load;

  @override
  State<VerseBlock> createState() => _VerseBlockState();
}

class _VerseBlockState extends State<VerseBlock> {
  Future<Verse?>? _future;
  String? _language;

  @override
  Widget build(BuildContext context) {
    final VerseProvider verses = AppScope.of(context).verses;
    return ListenableBuilder(
      listenable: verses,
      builder: (BuildContext context, Widget? _) {
        if (_future == null || _language != verses.value) {
          _language = verses.value;
          _future = widget.load(verses);
        }
        return FutureBuilder<Verse?>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<Verse?> snapshot) {
            final Verse? v = snapshot.data;
            if (v == null) {
              return const SizedBox.shrink();
            }
            return VerseCard(text: v.text, reference: AppLocalizations.of(context).reference(v.ref), translation: v.translationId);
          },
        );
      },
    );
  }
}
