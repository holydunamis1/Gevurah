import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/catalog/training_lessons.dart';
import '../core/catalog/struggle_catalog.dart';
import '../core/config/app_config.dart';
import '../core/models/daily_challenge.dart';
import '../core/models/fight_config.dart';
import '../core/models/loadout.dart';
import '../core/models/settings_model.dart';
import '../core/ports/audio_port.dart';
import '../game/tuning.dart';
import '../l10n/app_localizations.dart';
import '../platform/url_service.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
import '../providers/fight_provider.dart';
import '../screens/achievements_screen.dart';
import '../screens/card_picker_screen.dart';
import '../screens/daily_bout_screen.dart';
import '../screens/fight_screen.dart';
import '../screens/home_screen.dart';
import '../screens/how_to_play_screen.dart';
import '../screens/journey_map_screen.dart';
import '../screens/licenses_screen.dart';
import '../screens/mode_intro_screen.dart';
import '../screens/modes_screen.dart';
import '../screens/result_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/parts/lesson_parts.dart';
import '../screens/training_screen.dart';
import '../screens/trials_screen.dart';
import '../screens/upgrade_screen.dart';
import '../screens/verse_library_screen.dart';
import '../screens/error_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_header.dart';
import 'fatal_error.dart';

/// Route names the flow relies on.
abstract final class RouteNames {
  static const String opponent = 'opponent';
  static const String fight = 'fight';
}

/// The struggle Endurance is fought against (the last one, Giving Up).
const String enduranceStruggleId = 'giving_up';

/// What fills the screen under the menu routes.
enum _Stage { fight, result, menu }

/// The app: theme, language, direction, one Navigator and the flow between
/// screens. Screens take callbacks; everything that connects them is here.
class GevurahApp extends StatefulWidget {
  const GevurahApp({
    super.key,
    required this.providers,
    required this.urls,
    this.setOrientations = SystemChrome.setPreferredOrientations,
    this.dailyTaps,
    this.launchedFromReminder,
    this.fatalErrors,
    this.exportLog,
  });

  final AppProviders providers;
  final UrlService urls;

  /// Asks the device to hold orientations; replaceable for tests.
  final Future<void> Function(List<DeviceOrientation> orientations) setOrientations;

  /// Emits when the player taps the daily reminder while the app runs.
  final Stream<void>? dailyTaps;

  /// Tells whether the app was opened by tapping the reminder while closed.
  final Future<bool> Function()? launchedFromReminder;

  /// Shows the full-screen fallback while it is raised.
  final FatalErrorHost? fatalErrors;

  /// The recent local log as text, attached to the email report.
  final Future<String> Function()? exportLog;

  @override
  State<GevurahApp> createState() => _GevurahAppState();
}

class _GevurahAppState extends State<GevurahApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _taps;
  String? _syncedLanguage;

  /// What the app shows underneath every menu route: the fight (the app opens
  /// into one), the result of a bout, or the menu.
  final ValueNotifier<_Stage> _stage = ValueNotifier<_Stage>(_Stage.menu);
  int _boutId = 0;

  AppProviders get app => widget.providers;

  @override
  void initState() {
    super.initState();
    unawaited(widget.setOrientations(FightScreen.menuOrientations));
    _stage.addListener(_music);
    app.settings.addListener(_music);
    _playNext();
    _taps = widget.dailyTaps?.listen((_) => _openDaily());
    unawaited(_openDailyIfColdStart());
    app.locale.addListener(_syncReminder);
    _syncReminder();
  }

  @override
  void dispose() {
    app.locale.removeListener(_syncReminder);
    _stage.removeListener(_music);
    app.settings.removeListener(_music);
    _stage.dispose();
    unawaited(_taps?.cancel());
    super.dispose();
  }

  bool _musicPlaying = false;

  /// Music plays during a fight when sound and music are on, and stops
  /// everywhere else.
  void _music() {
    final AudioPort? a = app.audio;
    if (a == null) {
      return;
    }
    final SettingsModel s = app.settings.settings;
    final bool want = _stage.value == _Stage.fight && s.soundOn && s.musicOn;
    if (want == _musicPlaying) {
      return;
    }
    _musicPlaying = want;
    if (want) {
      unawaited(a.startLoop(GameTuning.soundMusic, volume: 0.35));
    } else {
      unawaited(a.stopLoop());
    }
  }

  /// The header's Sound icon switches every sound and the music together.
  void _toggleSound() {
    final SettingsModel s = app.settings.settings;
    final bool on = !(s.soundOn && s.musicOn);
    unawaited(app.settings.update((SettingsModel m) => m.copyWith(soundOn: on, musicOn: on)));
  }

  void _fromHeader(VoidCallback open) {
    _toMenu();
    _home();
    open();
  }

  /// A tap on the reminder while the app was closed opens the Daily Bout over
  /// Home, so Back lands on Home.
  Future<void> _openDailyIfColdStart() async {
    final Future<bool> Function()? launched = widget.launchedFromReminder;
    if (launched == null) {
      return;
    }
    bool fromReminder = false;
    try {
      fromReminder = await launched();
    } on Object {
      fromReminder = false;
    }
    if (fromReminder && mounted) {
      _openDaily();
    }
  }

  Future<void> _retryAfterFatal() async {
    widget.fatalErrors?.clear();
    _home();
  }

  Future<void> _reportFatal() async {
    final String log = await widget.exportLog?.call() ?? '';
    await widget.urls.openMail(subject: _reportSubject, body: log);
  }

  /// Subject of the emailed problem report.
  static const String _reportSubject = 'Gevurah Boxing problem';

  /// Re-applies the saved reminder at launch and when the language changes, so
  /// its text is in the player's language.
  void _syncReminder() {
    final String code = app.locale.value;
    if (_syncedLanguage == code) {
      return;
    }
    _syncedLanguage = code;
    final Locale locale = _supported(code);
    final AppLocalizations l = lookupAppLocalizations(locale);
    unawaited(app.reminder.sync(title: l.reminderTitle, body: l.reminderBody));
  }

  static Locale _supported(String code) {
    final Locale wanted = Locale(code);
    return AppLocalizations.supportedLocales.contains(wanted) ? wanted : const Locale('en');
  }

  NavigatorState get _nav => _navigator.currentState!;

  PageRoute<T> _route<T>(String name, WidgetBuilder builder) {
    final bool reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => builder(c),
      transitionDuration: reduce ? Duration.zero : const Duration(milliseconds: Motion.pushMs),
      reverseTransitionDuration: reduce ? Duration.zero : const Duration(milliseconds: Motion.popMs),
      transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> s, Widget child) {
        final Animation<double> eased = CurvedAnimation(parent: a, curve: Curves.easeInOut);
        if (reduce) {
          return child;
        }
        final double toward = Directionality.of(c) == TextDirection.rtl ? -1 : 1;
        return FadeTransition(
          opacity: eased,
          child: AnimatedBuilder(
            animation: eased,
            builder: (BuildContext _, Widget? inner) => Transform.translate(offset: Offset(toward * Motion.slidePx * (1 - eased.value), 0), child: inner),
            child: child,
          ),
        );
      },
    );
  }

  void _push(String name, WidgetBuilder builder) => unawaited(_nav.push<void>(_route<void>(name, builder)));

  void _pop() => _nav.pop();

  void _home() => _navigator.currentState?.popUntil((Route<dynamic> r) => r.isFirst);

  /// Leaves any bout in progress and shows the menu.
  void _toMenu() {
    if (_stage.value == _Stage.fight) {
      app.fight.abandon();
    }
    _stage.value = _Stage.menu;
  }

  // ---- Flow ---------------------------------------------------------------

  /// Starts a bout against [struggleId] with the equipped cards and stance and
  /// shows the fight at once. Menu routes above are closed.
  void _play(String struggleId, FightMode mode, {DailyChallenge? daily, Difficulty difficulty = Difficulty.standard}) {
    final Loadout loadout = app.loadout.value.loadout;
    final int seed = daily?.seed ?? app.fight.clock.now().millisecondsSinceEpoch & 0x7fffffff;
    final bool started = app.fight.start(
      FightConfig(
        mode: mode,
        struggleId: struggleId,
        cardIds: loadout.cardIds,
        stance: loadout.stance,
        seed: seed,
        difficulty: difficulty,
        timingAssist: true,
        easy: true,
      ),
      daily: daily,
    );
    if (!started) {
      return;
    }
    _home();
    _boutId++;
    _stage.value = _Stage.fight;
  }

  /// The next career opponent, or the first when every one is cleared.
  void _playNext() {
    final String id = HomeScreen.nextStruggle(app.progress.value.progress) ?? StruggleCatalog.career.first.id;
    _play(id, FightMode.journey);
  }

  /// The same opponent again with a fresh seed (never the Daily Bout).
  void _playAgain() {
    final FightView? v = app.fight.value;
    if (v == null || v.config.mode == FightMode.daily) {
      _toMenu();
      return;
    }
    _play(v.config.struggleId, v.config.mode, difficulty: v.config.difficulty);
  }

  Widget _fightScreen(BuildContext _) => FightScreen(
        key: ValueKey<int>(_boutId),
        setOrientations: widget.setOrientations,
        onFinished: () => _stage.value = _Stage.result,
        onLeave: _toMenu,
      );

  /// The rewarded retry after a loss: the new bout is already started.
  void _retryBout() {
    _boutId++;
    _stage.value = _Stage.fight;
  }

  Widget _resultScreen() => ResultScreen(
        onContinue: _playNext,
        onTryAgain: _playAgain,
        onHome: _toMenu,
        onRetry: _retryBout,
      );

  void _openCards() => _push('cards', (BuildContext _) => CardPickerScreen(onBack: _pop));

  void _openJourney() => _push(
        'journey',
        (BuildContext _) => JourneyMapScreen(onOpen: (String id) => _play(id, FightMode.journey), onBack: _pop),
      );

  void _openTrials() => _push(
        'trials',
        (BuildContext _) => TrialsScreen(onOpen: (String id) => _play(id, FightMode.trials), onBack: _pop),
      );

  void _openDaily() {
    _toMenu();
    _pushDaily();
  }

  void _pushDaily() => _push(
        'daily',
        (BuildContext _) => DailyBoutScreen(
          onStart: (DailyChallenge c) => _play(c.struggleId, FightMode.daily, daily: c),
          onBack: _pop,
        ),
      );

  void _openModes() => _push(
        'modes',
        (BuildContext _) => ModesScreen(onChoose: _openMode, onBack: _pop),
      );

  void _openMode(FightMode mode) {
    switch (mode) {
      case FightMode.journey:
        _openJourney();
      case FightMode.trials:
        _openTrials();
      case FightMode.daily:
        _openDaily();
      case FightMode.training:
        _openTraining();
      case FightMode.sparring:
      case FightMode.endurance:
        _push(
          'mode-intro',
          (BuildContext _) => ModeIntroScreen(
            mode: mode,
            onChoose: (String? id, Difficulty d) => _play(id ?? enduranceStruggleId, mode, difficulty: d),
            onBack: _pop,
          ),
        );
    }
  }

  void _openHowToPlay() => _push('how-to-play', (BuildContext _) => HowToPlayScreen(onBack: _pop));

  void _openTraining() => _push(
        'training',
        (BuildContext _) => TrainingScreen(
          onLesson: _startLesson,
          onPractice: _openPractice,
          onHowToPlay: _openHowToPlay,
          onBack: _pop,
        ),
      );

  void _openPractice() => _push(
        'mode-intro',
        (BuildContext _) => ModeIntroScreen(
          mode: FightMode.training,
          onChoose: (String? id, Difficulty d) => _play(id ?? enduranceStruggleId, FightMode.training, difficulty: d),
          onBack: _pop,
        ),
      );

  /// Starts a lesson's fixed bout and opens the fight with its goal strip.
  void _startLesson(TrainingLesson lesson) {
    if (!app.fight.start(lesson.config)) {
      return;
    }
    final TrainingLesson? next = TrainingLessons.after(lesson.id);
    _push(
      RouteNames.fight,
      (BuildContext _) => FightScreen(
        setOrientations: widget.setOrientations,
        onFinished: _pop,
        onLeave: _pop,
        lesson: LessonRun(
          lesson: lesson,
          onNext: next == null
              ? null
              : () => _leaveThenStart(next),
          onRepeat: () => _leaveThenStart(lesson),
          onExit: () {
            app.fight.abandon();
            _pop();
          },
        ),
      ),
    );
  }

  /// Leaves the lesson's fight, then starts [lesson] once the old screen is
  /// gone, so two fight screens never share one bout.
  void _leaveThenStart(TrainingLesson lesson) {
    app.fight.abandon();
    _pop();
    final bool reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    Timer(reduce ? Duration.zero : const Duration(milliseconds: Motion.popMs + 60), () {
      if (mounted) {
        _startLesson(lesson);
      }
    });
  }

  void _openLibrary() => _push('library', (BuildContext _) => VerseLibraryScreen(onBack: _pop));

  void _openAchievements() => _push('achievements', (BuildContext _) => AchievementsScreen(onBack: _pop));

  void _openUpgrade() => _push('upgrade', (BuildContext _) => UpgradeScreen(onBack: _pop));

  void _openLicenses() => _push(
        'licenses',
        (BuildContext _) => LicensesScreen(
          loadNotices: app.verses.notices,
          onOpenLink: (String url) => unawaited(widget.urls.openLink(url)),
          onBack: _pop,
        ),
      );

  void _openSettings() => _push(
        'settings',
        (BuildContext _) => SettingsScreen(
          onBack: _pop,
          onAchievements: _openAchievements,
          onUpgrade: _openUpgrade,
          onSupport: () => unawaited(widget.urls.openLink(AppConfig.supportUrl)),
          onPrivacyPolicy: () => unawaited(widget.urls.openLink(AppConfig.privacyUrl)),
          onLicenses: _openLicenses,
          onHowToPlay: _openHowToPlay,
        ),
      );

  Widget _first() {
    return ValueListenableBuilder<_Stage>(
      valueListenable: _stage,
      builder: (BuildContext context, _Stage stage, Widget? _) {
        switch (stage) {
          case _Stage.fight:
            return _fightScreen(context);
          case _Stage.result:
            return _resultScreen();
          case _Stage.menu:
            return HomeScreen(
              onContinue: (String id) => _play(id, FightMode.journey),
              onJourney: _openJourney,
              onDaily: _openDaily,
              onModes: _openModes,
              onCards: _openCards,
              onLibrary: _openLibrary,
              onSettings: _openSettings,
            );
        }
      },
    );
  }

  /// The one header above every screen. The screens below it take no top inset
  /// of their own.
  Widget _withHeader(Widget child) {
    return Builder(
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context);
        final AppTheme theme = AppTheme.of(context);
        return ColoredBox(
          color: theme.palette.bgPrimary,
          // Bottom-up, so the header is painted after the screens: a route blocks
          // the semantics of anything painted before it, and the header must stay
          // readable to a screen reader.
          child: Column(
            verticalDirection: VerticalDirection.up,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
              SafeArea(
                bottom: false,
                child: ListenableBuilder(
                  listenable: Listenable.merge(<Listenable>[app.settings, app.daily]),
                  builder: (BuildContext context, Widget? _) {
                    final SettingsModel s = app.settings.settings;
                    return AppHeader(
                      wordmark: l.appName,
                      mapLabel: l.homeJourney,
                      dailyLabel: l.homeDaily,
                      soundLabel: l.settingsSound,
                      settingsLabel: l.homeSettings,
                      soundOn: s.soundOn && s.musicOn,
                      showDaily: app.daily.value.enabled,
                      onMap: () => _fromHeader(_openJourney),
                      onDaily: () => _fromHeader(_openDaily),
                      onSound: _toggleSound,
                      onSettings: () => _fromHeader(_openSettings),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _withFallback(Widget child) {
    final FatalErrorHost? host = widget.fatalErrors;
    if (host == null) {
      return child;
    }
    return ListenableBuilder(
      listenable: host,
      builder: (BuildContext context, Widget? _) => Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          if (host.value)
            Positioned.fill(
              child: ErrorScreen(onRetry: () => unawaited(_retryAfterFatal()), onReport: () => unawaited(_reportFatal())),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[app.locale, app.theme]),
      builder: (BuildContext context, Widget? _) {
        final Locale locale = _supported(app.locale.value);
        return WidgetsApp(
          color: const Color(0xFF000000),
          navigatorKey: _navigator,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) => _route<T>(settings.name ?? '', builder),
          home: _first(),
          builder: (BuildContext context, Widget? child) {
            final bool dark = app.theme.isDark(MediaQuery.platformBrightnessOf(context) == Brightness.dark);
            return AppScope(
              providers: app,
              child: Directionality(
                textDirection: app.locale.isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
                child: AppTheme.forBrightness(
                  brightness: dark ? Brightness.dark : Brightness.light,
                  child: _withFallback(_withHeader(child ?? const SizedBox.shrink())),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
