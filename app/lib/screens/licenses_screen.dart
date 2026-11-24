import 'package:flutter/widgets.dart';

import '../core/models/license_notice.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/nav_bar.dart';
import '../widgets/screen_frame.dart';

/// The notice for every bundled source: its name, its license, the exact
/// attribution line the license asks for, and a link to the license page.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key, required this.loadNotices, required this.onOpenLink, required this.onBack});

  /// Loads the notices; the shell passes the verse repository's.
  final Future<List<LicenseNotice>> Function() loadNotices;

  /// Opens a license page outside the app.
  final ValueChanged<String> onOpenLink;
  final VoidCallback onBack;

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<List<LicenseNotice>> _future = _load();

  Future<List<LicenseNotice>> _load() async {
    try {
      return await widget.loadNotices();
    } on Object {
      return const <LicenseNotice>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    return ScreenFrame(
      navBar: NavBar(title: l.licensesTitle, onBack: widget.onBack, backLabel: l.commonBack),
      child: FutureBuilder<List<LicenseNotice>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<LicenseNotice>> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final List<LicenseNotice> notices = snapshot.data!;
          if (notices.isEmpty) {
            return EmptyState(icon: AppIcons.info, title: l.licensesEmpty);
          }
          return ListView(
            padding: const EdgeInsets.all(Sp.lg),
            children: <Widget>[
              Text(l.licensesIntro, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              const SizedBox(height: Sp.md),
              for (final LicenseNotice n in notices) ...<Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(n.sourceName, style: theme.text.title2),
                      const SizedBox(height: Sp.xxs),
                      Text(n.license, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
                      if (n.attribution.isNotEmpty) ...<Widget>[
                        const SizedBox(height: Sp.sm),
                        Text(n.attribution, style: theme.text.body),
                      ],
                    ],
                  ),
                ),
                AppRow(label: l.licensesLink, leadingIcon: AppIcons.externalLink, showChevron: false, onPressed: () => widget.onOpenLink(n.link)),
                const SizedBox(height: Sp.md),
              ],
            ],
          );
        },
      ),
    );
  }
}
