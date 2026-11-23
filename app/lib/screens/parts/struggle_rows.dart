import 'package:flutter/widgets.dart';

import '../../core/catalog/struggle_catalog.dart';
import '../../core/models/progress.dart';
import '../../core/models/struggle_def.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../theme/icon_aliases.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/star_row.dart';

/// One card per struggle: its name, whether it is locked, ready or overcome,
/// and its best stars. A locked struggle cannot be pressed.
List<Widget> struggleRows({
  required AppLocalizations l,
  required List<String> ids,
  required Set<String> openIds,
  required Progress progress,
  required ValueChanged<String> onOpen,
}) {
  final List<Widget> out = <Widget>[];
  for (final String id in ids) {
    final StruggleDef? def = StruggleCatalog.byId(id);
    final BoutRecord? record = progress.bouts[id];
    final bool won = (record?.wins ?? 0) > 0;
    final bool open = openIds.contains(id);
    final String state = won ? l.stateOvercome : (open ? l.stateReady : l.stateLocked);
    out.add(
      AppCard(
        leadingIcon: won ? AppIcons.check : (open ? AppIcons.fight : AppIcons.locked),
        label: l.struggleName(id),
        value: def != null && def.isFinal ? '${l.journeyFinal} · $state' : state,
        showChevron: open,
        onPressed: open ? () => onOpen(id) : null,
      ),
    );
    if (won) {
      out.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(start: Sp.md, top: Sp.xs),
          child: Align(alignment: AlignmentDirectional.centerStart, child: StarRow(stars: record!.stars, label: l.resultStars(record.stars))),
        ),
      );
    }
    out.add(const SizedBox(height: Sp.md));
  }
  return out;
}
