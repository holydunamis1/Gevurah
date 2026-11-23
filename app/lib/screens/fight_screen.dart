import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/input/tap_swipe_strategy.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../game/boxing_game.dart';
import '../game/fight_arena.dart';
import '../game/fight_controller.dart';
import '../game/hud/fight_hud.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/fight_provider.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_row.dart';
import '../widgets/bottom_sheet.dart';
import 'corner_screen.dart';
import 'ten_count_screen.dart';

/// The bout. The arena runs the fight; the corner and the ten-count appear
/// over it as pauses; the pause sheet offers Resume or Leave. Scripture only
/// ever appears in those pauses, never over live action.
class FightScreen extends StatefulWidget {
  const FightScreen({super.key, required this.onFinished, required this.onLeave});

  /// The bout ended; the result screen takes over.
  final VoidCallback onFinished;

  /// The player left; nothing was recorded.
  final VoidCallback onLeave;

  @override
  State<FightScreen> createState() => _FightScreenState();
}

enum _Pause { none, corner, tenCount }

class _FightScreenState extends State<FightScreen> {
  FightController? _controller;
  BoxingGame? _game;
  StreamSubscription<FightEvent>? _sub;
  _Pause _pause = _Pause.none;
  bool _sheetOpen = false;

  FightController _ensure(AppProviders app) {
    final FightController? existing = _controller;
    if (existing != null) {
      return existing;
    }
    final FightController c = FightController(
      fight: app.fight,
      input: TapSwipeStrategy(),
      nowMs: FightController.stopwatchClock(),
      haptics: app.haptics,
      audio: app.audio,
    );
    _sub = c.events.listen(_onEvent);
    _controller = c;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        c.begin();
      }
    });
    return c;
  }

  void _onEvent(FightEvent e) {
    switch (e) {
      case FightPaused(:final PauseReason reason):
        switch (reason) {
          case PauseReason.corner:
            setState(() => _pause = _Pause.corner);
          case PauseReason.tenCount:
            setState(() => _pause = _Pause.tenCount);
          case PauseReason.finished:
            widget.onFinished();
          case PauseReason.user:
            {}
        }
      case FightResumed():
        if (_pause != _Pause.none) {
          setState(() => _pause = _Pause.none);
        }
      case TelegraphStarted():
      case ResponseRegistered():
      case OpeningOpened():
      case ExchangeResolved():
        {}
    }
  }

  Future<void> _showPause(AppLocalizations l, FightController c) async {
    if (_sheetOpen) {
      return;
    }
    _sheetOpen = true;
    c.pause();
    final bool leave = await showAppBottomSheet<bool>(
          context,
          barrierLabel: l.fightResume,
          builder: (BuildContext sheet) => _PauseSheet(l: l),
        ) ??
        false;
    _sheetOpen = false;
    if (!mounted) {
      return;
    }
    if (!leave) {
      c.resume();
      return;
    }
    final bool sure = await showAppDialog<bool>(
          context,
          barrierLabel: l.fightStay,
          dialog: AppDialog(
            title: l.fightLeaveTitle,
            message: l.fightLeaveBody,
            primary: AppDialogAction(label: l.fightStay, onPressed: () => Navigator.of(context).pop(false)),
            secondary: AppDialogAction(label: l.fightLeave, onPressed: () => Navigator.of(context).pop(true)),
          ),
        ) ??
        false;
    if (!mounted) {
      return;
    }
    if (sure) {
      AppScope.of(context).fight.abandon();
      widget.onLeave();
    } else {
      c.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    final AppTheme theme = AppTheme.of(context);
    final FightView? view = app.fight.value;
    if (view == null) {
      return const SizedBox.shrink();
    }
    final FightController c = _ensure(app);
    final BoxingGame game = _game ??= BoxingGame(
      controller: c,
      palette: theme.palette,
      struggleId: view.struggle.id,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    final FightHudLabels labels = FightHudLabels(
      resolve: l.hudResolve,
      stamina: l.hudStamina,
      weight: l.hudWeight,
      breath: l.hudBreath,
      pause: l.hudPause,
      roundLabel: (int round) => l.roundLabel(round, 3),
      moveName: l.moveName,
    );
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            FightArena(game: game, controller: c, labels: labels, locale: app.locale.value, onPause: () => unawaited(_showPause(l, c))),
            if (_pause == _Pause.corner)
              CornerScreen(
                round: view.state.round,
                onNextRound: () {
                  app.fight.endCorner();
                  c.resume();
                },
              ),
            if (_pause == _Pause.tenCount)
              TenCountScreen(
                onRise: (int goodTaps) {
                  app.fight.rise(goodTaps);
                  c.resume();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_controller?.dispose());
    super.dispose();
  }
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: l.fightPauseTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppRow(label: l.fightResume, onPressed: () => Navigator.of(context).pop(false)),
          const SizedBox(height: Sp.xs),
          AppRow(label: l.fightLeave, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}
