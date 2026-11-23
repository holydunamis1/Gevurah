import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/models/curated_verse.dart';
import '../game/fight_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import '../widgets/primary_button.dart';
import 'parts/verse_block.dart';

/// The ten-count after a knockdown: a get-up verse and a button to tap in a
/// steady rhythm. Each tap spaced steadily after the last counts as a good tap.
/// After [targetTaps] taps, or [limit], the player stands and [onRise] is
/// called with the good taps.
class TenCountScreen extends StatefulWidget {
  const TenCountScreen({super.key, required this.onRise, this.nowMs, this.limit = const Duration(seconds: 10)});

  static const int targetTaps = 6;

  /// A tap counts as steady when it comes between these gaps after the last.
  static const double minGapMs = 250;
  static const double maxGapMs = 900;

  final ValueChanged<int> onRise;

  /// A monotonic clock in milliseconds; the real one by default.
  final double Function()? nowMs;
  final Duration limit;

  /// Whether a tap [gapMs] after the previous one is steady.
  static bool isSteady(double gapMs) => gapMs >= minGapMs && gapMs <= maxGapMs;

  @override
  State<TenCountScreen> createState() => _TenCountScreenState();
}

class _TenCountScreenState extends State<TenCountScreen> {
  late final double Function() _now = widget.nowMs ?? FightController.stopwatchClock();
  Timer? _timer;
  double? _last;
  int _taps = 0;
  int _good = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.limit, _finish);
  }

  void _finish() {
    if (_done) {
      return;
    }
    _done = true;
    _timer?.cancel();
    widget.onRise(_good);
  }

  void _tap() {
    if (_done) {
      return;
    }
    final double now = _now();
    final double? last = _last;
    final bool steady = last == null || TenCountScreen.isSteady(now - last);
    _last = now;
    setState(() {
      _taps++;
      if (steady) {
        _good++;
      }
    });
    if (_taps >= TenCountScreen.targetTaps) {
      _finish();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppTheme theme = AppTheme.of(context);
    final Widget verse = SingleChildScrollView(child: VerseBlock(load: (verses) => verses.forMoment(VerseMoment.tenCount, seed: 7)));
    final Widget controls = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(l.tenProgress(_taps, TenCountScreen.targetTaps), textAlign: TextAlign.center, style: theme.text.title2),
          ),
          const SizedBox(height: Sp.md),
          PrimaryButton(label: l.tenTap, icon: AppIcons.strike, onPressed: _tap),
          const SizedBox(height: Sp.sm),
          PrimaryButton(label: l.tenStand, onPressed: _finish),
        ],
      ),
    );
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final Widget heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l.tenTitle, style: theme.text.headline),
                const SizedBox(height: Sp.xs),
                Text(l.tenBody, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
              ],
            );
            if (box.maxWidth > box.maxHeight) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[heading, const SizedBox(height: Sp.md), Expanded(child: verse)],
                    ),
                  ),
                  const SizedBox(width: Sp.lg),
                  Expanded(child: Center(child: controls)),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[heading, const SizedBox(height: Sp.lg), Expanded(child: verse), const SizedBox(height: Sp.md), controls],
            );
          },
        ),
      ),
    );
  }
}
