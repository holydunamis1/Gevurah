import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/catalog/training_lessons.dart';
import '../core/input/tap_swipe_strategy.dart';
import '../core/models/fight_config.dart';
import '../core/models/player_state.dart';
import '../core/models/settings_model.dart';
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
import 'parts/lesson_parts.dart';
import 'ten_count_screen.dart';

/// The bout. The arena runs the fight; the corner and the ten-count appear
/// over it as pauses; the pause sheet offers Resume or Leave. Scripture only
/// ever appears in those pauses, never over live action.
class FightScreen extends StatefulWidget {
  const FightScreen({
    super.key,
    required this.onFinished,
    required this.onLeave,
    this.lesson,
    this.setOrientations = SystemChrome.setPreferredOrientations,
  });

  /// Asks the device to hold these orientations. The fight is landscape; the
  /// rest of the app is portrait. Replaceable for tests.
  final Future<void> Function(List<DeviceOrientation> orientations) setOrientations;

  /// The fight is played in landscape.
  static const List<DeviceOrientation> fightOrientations = <DeviceOrientation>[DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];

  /// The rest of the app is portrait.
  static const List<DeviceOrientation> menuOrientations = <DeviceOrientation>[DeviceOrientation.portraitUp];

  /// Set when the bout is a Training lesson: a goal strip is drawn, the lesson
  /// ends the moment its goal is met, and the result screen is skipped.
  final LessonRun? lesson;

  /// The bout ended; the result screen takes over.
  final VoidCallback onFinished;

  /// The player left; nothing was recorded.
  final VoidCallback onLeave;

  @override
  State<FightScreen> createState() => _FightScreenState();
}

enum _Pause { none, corner, tenCount }

enum _LessonEnd { none, met, notYet }

class _FightScreenState extends State<FightScreen> {
  FightController? _controller;
  BoxingGame? _game;
  StreamSubscription<FightEvent>? _sub;
  _Pause _pause = _Pause.none;
  bool _sheetOpen = false;
  _LessonEnd _lessonEnd = _LessonEnd.none;

  @override
  void initState() {
    super.initState();
    unawaited(widget.setOrientations(FightScreen.fightOrientations));
  }

  AppProviders? _app;

  FightView? get _lessonView => _app?.fight.value;

  FightController _ensure(AppProviders app) {
    _app = app;
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
    if (widget.lesson != null) {
      app.fight.addListener(_checkLesson);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        c.begin();
      }
    });
    return c;
  }

  /// Ends the lesson the moment its goal is met.
  void _checkLesson() {
    final LessonRun? run = widget.lesson;
    final FightView? v = _lessonView;
    if (run == null || v == null || _lessonEnd != _LessonEnd.none) {
      return;
    }
    final bool breathUsed = v.state.player.breathCharges < PlayerState.breathPerRound;
    if (TrainingLessons.isMet(run.lesson, v.history, breathUsed: breathUsed)) {
      _controller?.pause();
      setState(() => _lessonEnd = _LessonEnd.met);
      final AppProviders app = _app!;
      final String id = run.lesson.id;
      if (!app.settings.settings.trainingDone.contains(id)) {
        unawaited(app.settings.update((SettingsModel m) => m.copyWith(trainingDone: <String>[...m.trainingDone, id])));
      }
    }
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
            if (widget.lesson == null) {
              widget.onFinished();
            } else if (_lessonEnd == _LessonEnd.none) {
              setState(() => _lessonEnd = _LessonEnd.notYet);
            }
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
      roundLabel: view.config.mode == FightMode.endurance ? l.enduranceRound : (int round) => l.roundLabel(round, 3),
      moveName: l.moveName,
    );
    return ColoredBox(
      color: theme.palette.bgPrimary,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            FightArena(game: game, controller: c, labels: labels, locale: app.locale.value, onPause: () => unawaited(_showPause(l, c))),
            if (widget.lesson != null)
              ListenableBuilder(
                listenable: app.fight,
                builder: (BuildContext context, Widget? _) {
                  final FightView now = app.fight.value ?? view;
                  final bool breathUsed = now.state.player.breathCharges < PlayerState.breathPerRound;
                  return LessonCoach(lesson: widget.lesson!.lesson, done: TrainingLessons.progress(widget.lesson!.lesson, now.history, breathUsed: breathUsed));
                },
              ),
            if (widget.lesson == null && app.progress.value.progress.bouts.isEmpty)
              Positioned(
                top: Sp.xxl,
                left: Sp.lg,
                right: Sp.lg,
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: app.fight,
                    builder: (BuildContext context, Widget? _) {
                      final FightView now = app.fight.value ?? view;
                      if (now.history.length >= 4 || _pause != _Pause.none) {
                        return const SizedBox.shrink();
                      }
                      return Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: theme.palette.bgSecondary, borderRadius: BorderRadius.circular(Radii.chip), border: Border.all(color: theme.palette.hairline, width: Strokes.hairline)),
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm), child: Text(l.fightCue, style: theme.text.callout)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_pause == _Pause.corner)
              ListenableBuilder(
                listenable: app.fight,
                builder: (BuildContext context, Widget? _) {
                  final FightView now = app.fight.value ?? view;
                  return CornerScreen(
                    round: now.state.round,
                    stance: now.stance,
                    onStance: app.fight.changeStance,
                    onNextRound: () {
                      app.fight.endCorner();
                      c.resume();
                    },
                  );
                },
              ),
            if (_pause == _Pause.tenCount)
              TenCountScreen(
                onRise: (int goodTaps) {
                  app.fight.rise(goodTaps);
                  c.resume();
                },
              ),
            if (widget.lesson != null && _lessonEnd != _LessonEnd.none)
              Positioned.fill(child: LessonOverlay(run: widget.lesson!, met: _lessonEnd == _LessonEnd.met)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _app?.fight.removeListener(_checkLesson);
    unawaited(_sub?.cancel());
    unawaited(_controller?.dispose());
    unawaited(widget.setOrientations(FightScreen.menuOrientations));
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
