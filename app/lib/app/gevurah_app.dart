import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import '../screens/journey_map_screen.dart';
import '../screens/licenses_screen.dart';
import '../screens/mode_intro_screen.dart';
import '../screens/modes_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/opponent_card_screen.dart';
import '../screens/result_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/trials_screen.dart';
import '../screens/upgrade_screen.dart';
import '../screens/verse_library_screen.dart';
import '../theme/app_theme.dart';

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
  });

  final AppProviders providers;
  final UrlService urls;

  /// Asks the device to hold orientations; replaceable for tests.
  final Future<void> Function(List<DeviceOrientation> orientations) setOrientations;

  /// Emits when the player taps the daily reminder while the app runs.
  final Stream<void>? dailyTaps;

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
    app.locale.addListener(_syncReminder);
    _syncReminder();
  }

  @override
  void dispose() {
    app.locale.removeListener(_syncReminder);
    unawaited(_taps?.cancel());
    super.dispose();
  }

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

  PageRoute<T> _route<T>(String name, WidgetBuilder builder) => PageRouteBuilder<T>(
        settings: RouteSettings(name: name),
        pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => builder(c),
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> s, Widget child) =>
            MediaQuery.disableAnimationsOf(c) ? child : FadeTransition(opacity: a, child: child),
      );

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
      case FightMode.sparring:
      case FightMode.training:
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
          onSupport: () => unawaited(widget.urls.openMail()),
          onPrivacyPolicy: () => unawaited(widget.urls.openLink(_privacyUrl)),
          onLicenses: _openLicenses,
        ),
      );

  /// The privacy policy page; empty until the website is live.
  static const String _privacyUrl = '';

  Widget _first() {
    return ListenableBuilder(
      listenable: app.settings,
      builder: (BuildContext context, Widget? _) {
        if (!app.settings.settings.onboardingDone) {
          return OnboardingScreen(onDone: () {});
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
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
