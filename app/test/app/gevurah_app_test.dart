import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/app/bootstrap.dart';
import 'package:gevurah/app/fatal_error.dart';
import 'package:gevurah/app/gevurah_app.dart';
import 'package:gevurah/l10n/app_localizations.dart';
import 'package:gevurah/platform/url_service.dart';
import 'package:gevurah/screens/daily_bout_screen.dart';
import 'package:gevurah/screens/error_screen.dart';
import 'package:gevurah/screens/fight_screen.dart';
import 'package:gevurah/screens/home_screen.dart';
import 'package:gevurah/screens/onboarding_screen.dart';
import 'package:gevurah/screens/settings_screen.dart';

import '../screens/screens_test.dart' show Rigging, makeApp, playOut;

Future<void> noOrientation(List<DeviceOrientation> o) async {}

Future<void> pumpApp(WidgetTester t, Rigging r, {List<String>? opened, Future<bool> Function()? launched, FatalErrorHost? fatal, Future<String> Function()? exportLog}) async {
  await t.pumpWidget(
    GevurahApp(
      providers: r.app,
      urls: UrlService(
        supportEmail: 'a@b.c',
        launcher: (Uri u) async {
          opened?.add(u.toString());
          return true;
        },
      ),
      setOrientations: noOrientation,
      launchedFromReminder: launched,
      fatalErrors: fatal,
      exportLog: exportLog,
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

Future<void> go(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  final AppLocalizations l = lookupAppLocalizations(const Locale('en'));

  testWidgets('first run shows onboarding, then Home after Play', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await pumpApp(t, r);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await t.tap(find.text(l.onboardingPlay));
    await go(t);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('a returning player goes straight to Home', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Settings opens from Home and Back returns', (WidgetTester t) async {
    final SemanticsHandle h = t.ensureSemantics();
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r);
    await t.tap(find.bySemanticsLabel(l.homeSettings));
    await go(t);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await t.tap(find.bySemanticsLabel(l.commonBack));
    await go(t);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    h.dispose();
  });

  testWidgets('Journey, Modes and Cards open from Home', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r);
    for (final String label in <String>[l.homeJourney, l.homeModes, l.homeCards]) {
      await t.tap(find.text(label).first);
      await go(t);
      expect(find.byType(HomeScreen), findsNothing, reason: label);
      Navigator.of(t.element(find.byType(Navigator).first)).pop();
      await go(t);
      expect(find.byType(HomeScreen), findsOneWidget, reason: label);
    }
  });

  testWidgets('starting the first struggle reaches the fight and Leave returns', (WidgetTester t) async {
    final List<List<DeviceOrientation>> asked = <List<DeviceOrientation>>[];
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await t.pumpWidget(
      GevurahApp(
        providers: r.app,
        urls: UrlService(supportEmail: 'a@b.c', launcher: (Uri u) async => true),
        setOrientations: (List<DeviceOrientation> o) async => asked.add(o),
      ),
    );
    await go(t);
    expect(asked.first, <DeviceOrientation>[DeviceOrientation.portraitUp]);
    await t.tap(find.text(l.homeContinue).first);
    await go(t);
    await t.tap(find.text(l.opponentStart));
    await t.pump(const Duration(milliseconds: 500));
    expect(asked.last, isNot(<DeviceOrientation>[DeviceOrientation.portraitUp]));
    expect(r.app.fight.value, isNotNull);
  });

  testWidgets('a failed start-up shows the error screen and Retry tries again', (WidgetTester t) async {
    int attempts = 0;
    await t.pumpWidget(
      BootstrapApp(
        build: () async {
          attempts++;
          throw StateError('no');
        },
      ),
    );
    await t.pump();
    await t.pump();
    expect(find.text(l.errorTitle), findsOneWidget);
    await t.tap(find.text(l.errorRetry));
    await t.pump();
    await t.pump();
    expect(attempts, 2);
  });

  testWidgets('a cold start from the reminder opens the Daily Bout over Home', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r, launched: () async => true);
    expect(find.byType(DailyBoutScreen), findsOneWidget);
    Navigator.of(t.element(find.byType(DailyBoutScreen))).pop();
    await go(t);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a normal start does not open the Daily Bout', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r, launched: () async => false);
    expect(find.byType(DailyBoutScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('an uncaught error shows the fallback; Retry returns Home', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    final FatalErrorHost fatal = FatalErrorHost();
    await pumpApp(t, r, fatal: fatal);
    expect(find.byType(ErrorScreen), findsNothing);
    fatal.raise();
    await t.pump();
    expect(find.byType(ErrorScreen), findsOneWidget);
    await t.tap(find.text(l.errorRetry));
    await go(t);
    expect(find.byType(ErrorScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Report opens an email with the log attached', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    final FatalErrorHost fatal = FatalErrorHost()..raise();
    final List<String> opened = <String>[];
    await pumpApp(t, r, opened: opened, fatal: fatal, exportLog: () async => 'LOGTEXT');
    await t.tap(find.text(l.errorReport));
    await t.pump();
    await t.pump();
    expect(opened.single, contains('LOGTEXT'));
  });

  testWidgets('screens push in 350 ms and pop in 280 ms, instantly with Reduce Motion', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r);
    final SemanticsHandle h = t.ensureSemantics();
    await t.tap(find.bySemanticsLabel(l.homeSettings));
    await go(t);
    final ModalRoute<dynamic> route = ModalRoute.of(t.element(find.byType(SettingsScreen)))!;
    expect(route.transitionDuration, const Duration(milliseconds: 350));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 280));
    h.dispose();
  });

  testWidgets('with Reduce Motion a screen appears at once', (WidgetTester t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final SemanticsHandle h = t.ensureSemantics();
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r);
    await t.tap(find.bySemanticsLabel(l.homeSettings));
    await t.pump();
    await t.pump();
    final ModalRoute<dynamic> route = ModalRoute.of(t.element(find.byType(SettingsScreen)))!;
    expect(route.transitionDuration, Duration.zero);
    h.dispose();
  });

  testWidgets('a bout started from the app plays to its end', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    await pumpApp(t, r);
    await t.tap(find.text(l.homeContinue).first);
    await go(t);
    await t.tap(find.text(l.opponentStart));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byType(FightScreen), findsOneWidget);
    expect(r.app.fight.value, isNotNull);
    playOut(r.app);
    expect(r.app.fight.value!.finished, isTrue);
  });

  testWidgets('Settings opens the live privacy and support pages', (WidgetTester t) async {
    final SemanticsHandle h = t.ensureSemantics();
    final Rigging r = await makeApp();
    await r.app.settings.update((s) => s.copyWith(onboardingDone: true));
    final List<String> opened = <String>[];
    await pumpApp(t, r, opened: opened);
    await t.tap(find.bySemanticsLabel(l.homeSettings));
    await go(t);
    for (final String label in <String>[l.settingsPrivacy, l.settingsSupport]) {
      final Finder f = find.text(label);
      await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pump();
    }
    expect(opened, <String>['https://gevurah.holydunamis1.workers.dev/privacy', 'https://gevurah.holydunamis1.workers.dev/support']);
    h.dispose();
  });
}
