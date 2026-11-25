import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/catalog/training_lessons.dart';
import '../core/config/app_config.dart';
import '../core/models/daily_challenge.dart';
import '../core/models/fight_config.dart';
import '../l10n/app_localizations.dart';
import '../platform/url_service.dart';
import '../providers/app_providers.dart';
import '../providers/app_scope.dart';
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
import '../screens/onboarding_screen.dart';
import '../screens/opponent_card_screen.dart';
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
import 'fatal_error.dart';

/// Route names the flow relies on.
abstract final class RouteNames {
  static const String opponent = 'opponent';
  static const String fight = 'fight';
}

/// The struggle Endurance is fought against (the last one, Giving Up).
const String enduranceStruggleId = 'giving_up';

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

  AppProviders get app => widget.providers;

  @override
  void initState() {
    super.initState();
    unawaited(widget.setOrientations(FightScreen.menuOrientations));
    _taps = widget.dailyTaps?.listen((_) => _openDaily());
    unawaited(_openDailyIfColdStart());
    app.locale.addListener(_syncReminder);
    _syncReminder();
  }

  @override
  void dispose() {
    app.locale.removeListener(_syncReminder);
    unawaited(_taps?.cancel());
    super.dispose();
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
    if (fromReminder && mounted && app.settings.settings.onboardingDone) {
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

  void _home() => _nav.popUntil((Route<dynamic> r) => r.isFirst);

  // ---- Flow ---------------------------------------------------------------

  void _openOpponent(String struggleId, FightMode mode, {DailyChallenge? daily, Difficulty difficulty = Difficulty.standard}) {
    _push(
      RouteNames.opponent,
      (BuildContext _) => OpponentCardScreen(
        struggleId: struggleId,
        mode: mode,
        daily: daily,
        difficulty: difficulty,
        onStart: _openFight,
        onChangeCards: _openCards,
        onHowToPlay: _openHowToPlay,
        onBack: _pop,
      ),
    );
  }

  void _openFight() {
    _push(
      RouteNames.fight,
      (BuildContext _) => FightScreen(
        setOrientations: widget.setOrientations,
        onFinished: _openResult,
        onLeave: _pop,
      ),
    );
  }

  void _openResult() {
    unawaited(
      _nav.pushReplacement<void, void>(
        _route<void>(
          'result',
          (BuildContext _) => ResultScreen(
            onContinue: _afterResult,
            onTryAgain: _backToOpponent,
            onHome: _home,
          ),
        ),
      ),
    );
  }

  void _backToOpponent() => _nav.popUntil((Route<dynamic> r) => r.settings.name == RouteNames.opponent);

  /// Back to whatever opened the opponent card: the map, the list or Home.
  void _afterResult() {
    _backToOpponent();
    _nav.pop();
  }

  void _openCards() => _push('cards', (BuildContext _) => CardPickerScreen(onBack: _pop));

  void _openJourney() => _push(
        'journey',
        (BuildContext _) => JourneyMapScreen(onOpen: (String id) => _openOpponent(id, FightMode.journey), onBack: _pop),
      );

  void _openTrials() => _push(
        'trials',
        (BuildContext _) => TrialsScreen(onOpen: (String id) => _openOpponent(id, FightMode.trials), onBack: _pop),
      );

  void _openDaily() => _push(
        'daily',
        (BuildContext _) => DailyBoutScreen(
          onStart: (DailyChallenge c) => _openOpponent(c.struggleId, FightMode.daily, daily: c),
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
            onChoose: (String? id, Difficulty d) => _openOpponent(id ?? enduranceStruggleId, mode, difficulty: d),
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
          onChoose: (String? id, Difficulty d) => _openOpponent(id ?? enduranceStruggleId, FightMode.training, difficulty: d),
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
    return ListenableBuilder(
      listenable: app.settings,
      builder: (BuildContext context, Widget? _) {
        if (!app.settings.settings.onboardingDone) {
          return OnboardingScreen(onDone: _openHowToPlay);
        }
        return HomeScreen(
          onContinue: (String id) => _openOpponent(id, FightMode.journey),
          onJourney: _openJourney,
          onDaily: _openDaily,
          onModes: _openModes,
          onCards: _openCards,
          onLibrary: _openLibrary,
          onSettings: _openSettings,
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
                  child: _withFallback(child ?? const SizedBox.shrink()),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
