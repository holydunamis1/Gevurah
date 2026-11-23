import 'package:flutter/widgets.dart';

import '../core/catalog/struggle_catalog.dart';
import '../core/models/curated_verse.dart';
import '../core/models/progress.dart';
import '../core/models/struggle_def.dart';
import '../core/models/verse.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../theme/tokens.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/segmented_control.dart';
import 'parts/app_ad_slot.dart';
import 'parts/verse_list.dart';

enum LibraryTab { cards, struggles, moments }

/// The bundled scripture, read offline: the verses on the cards the player has
/// earned, the verse for each struggle met, and the verses shown between
/// rounds, after a down, after a bout and each day.
class VerseLibraryScreen extends StatefulWidget {
  const VerseLibraryScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<VerseLibraryScreen> createState() => _VerseLibraryScreenState();
}

class _VerseLibraryScreenState extends State<VerseLibraryScreen> {
  LibraryTab _tab = LibraryTab.cards;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.libraryTitle, onBack: widget.onBack, backLabel: l.commonBack),
      adSlot: const AppAdSlot(),
      child: ListenableBuilder(
        listenable: app.progress,
        builder: (BuildContext context, Widget? _) {
          final Progress progress = app.progress.value.progress;
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              SegmentedControl<LibraryTab>(
                options: <SegmentOption<LibraryTab>>[
                  SegmentOption<LibraryTab>(value: LibraryTab.cards, label: l.libraryTabCards),
                  SegmentOption<LibraryTab>(value: LibraryTab.struggles, label: l.libraryTabStruggles),
                  SegmentOption<LibraryTab>(value: LibraryTab.moments, label: l.libraryTabMoments),
                ],
                selected: _tab,
                onChanged: (LibraryTab t) => setState(() => _tab = t),
              ),
              const SizedBox(height: Sp.lg),
              ..._body(l, progress),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(AppLocalizations l, Progress progress) {
    switch (_tab) {
      case LibraryTab.cards:
        return <Widget>[
          VerseList(
            key: ValueKey<String>('cards-${progress.cardsEarned.join(',')}'),
            empty: l.libraryEmpty,
            load: (verses) async => <LabeledVerse>[
              for (final String id in progress.cardsEarned) ...<LabeledVerse>[...await _one(verses.card(id))],
            ],
          ),
        ];
      case LibraryTab.struggles:
        final List<String> met = <String>[for (final StruggleDef s in StruggleCatalog.all) if (progress.bouts.containsKey(s.id)) s.id];
        return <Widget>[
          VerseList(
            key: ValueKey<String>('struggles-${met.join(',')}'),
            empty: l.libraryEmptyStruggles,
            load: (verses) async => <LabeledVerse>[
              for (final String id in met) ...<LabeledVerse>[...await _one(verses.preBout(id), label: l.struggleName(id))],
            ],
          ),
        ];
      case LibraryTab.moments:
        return <Widget>[
          for (final (VerseMoment, String) m in <(VerseMoment, String)>[
            (VerseMoment.corner, l.libraryCorner),
            (VerseMoment.tenCount, l.libraryTenCount),
            (VerseMoment.win, l.libraryWin),
            (VerseMoment.loss, l.libraryLoss),
            (VerseMoment.daily, l.libraryDaily),
          ]) ...<Widget>[
            SectionHeader(m.$2),
            VerseList(
              key: ValueKey<String>('moment-${m.$1.name}'),
              load: (verses) async => <LabeledVerse>[for (final Verse v in await verses.all(m.$1)) LabeledVerse(v)],
            ),
          ],
        ];
    }
  }

  Future<List<LabeledVerse>> _one(Future<Verse?> verse, {String? label}) async {
    final Verse? v = await verse;
    return v == null ? const <LabeledVerse>[] : <LabeledVerse>[LabeledVerse(v, label: label)];
  }
}
