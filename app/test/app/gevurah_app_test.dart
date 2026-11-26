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
import 'package:gevurah/core/models/fight_config.dart';
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

/// The app opens into a fight; this leaves it through the pause sheet and
/// shows the menu.
Future<void> openMenu(WidgetTester t, AppLocalizations l) async {
  final SemanticsHandle h = t.ensureSemantics();
  await t.tap(find.bySemanticsLabel(l.hudPause));
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  await t.tap(find.text(l.fightLeave));
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  await t.tap(find.text(l.fightLeave));
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  h.dispose();
}

void main() {
  final AppLocalizations l = lookupAppLocalizations(const Locale('en'));

  testWidgets('the app opens straight into a fight, with no onboarding, and a one-line cue', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await pumpApp(t, r);
    expect(find.byType(FightScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(r.app.fight.value, isNotNull);
    expect(r.app.fight.value!.config.mode, FightMode.journey);
    expect(find.text(l.fightCue), findsOneWidget);
  });

  testWidgets('Leave from the pause sheet shows the menu', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await pumpApp(t, r);
    await openMenu(t, l);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FightScreen), findsNothing);
  });

  testWidgets('Settings opens from Home and Back returns', (WidgetTester t) async {
    final SemanticsHandle h = t.ensureSemantics();
    final Rigging r = await makeApp();
    await pumpApp(t, r);
    await openMenu(t, l);
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
    await pumpApp(t, r);
    await openMenu(t, l);
    for (final String label in <String>[l.homeJourney, l.homeModes, l.homeCards]) {
      await t.tap(find.text(label).first);
      await go(t);
      expect(find.byType(HomeScreen), findsNothing, reason: label);
      Navigator.of(t.element(find.byType(Navigator).first)).pop();
      await go(t);
      expect(find.byType(HomeScreen), findsOneWidget, reason: label);
    }
  });

  testWidgets('the fight holds landscape and Continue on the menu starts the next fight', (WidgetTester t) async {
    final List<List<DeviceOrientation>> asked = <List<DeviceOrientation>>[];
    final Rigging r = await makeApp();
    await t.pumpWidget(
      GevurahApp(
        providers: r.app,
        urls: UrlService(supportEmail: 'a@b.c', launcher: (Uri u) async => true),
        setOrientations: (List<DeviceOrientation> o) async => asked.add(o),
      ),
    );
    await go(t);
    expect(asked.first, <DeviceOrientation>[DeviceOrientation.portraitUp]);
    expect(asked.last, FightScreen.fightOrientations);
    await openMenu(t, l);
    expect(asked.last, FightScreen.menuOrientations);
    await t.tap(find.text(l.homeContinue).first);
    await go(t);
    expect(find.byType(FightScreen), findsOneWidget);
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
    await pumpApp(t, r, launched: () async => true);
    expect(find.byType(DailyBoutScreen), findsOneWidget);
    Navigator.of(t.element(find.byType(DailyBoutScreen))).pop();
    await go(t);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a normal start does not open the Daily Bout', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await pumpApp(t, r, launched: () async => false);
    expect(find.byType(DailyBoutScreen), findsNothing);
    expect(find.byType(FightScreen), findsOneWidget);
  });

  testWidgets('an uncaught error shows the fallback; Retry returns to the game', (WidgetTester t) async {
    final Rigging r = await makeApp();
    final FatalErrorHost fatal = FatalErrorHost();
    await pumpApp(t, r, fatal: fatal);
    expect(find.byType(ErrorScreen), findsNothing);
    fatal.raise();
    await t.pump();
    expect(find.byType(ErrorScreen), findsOneWidget);
    await t.tap(find.text(l.errorRetry));
    await go(t);
    expect(find.byType(ErrorScreen), findsNothing);
    expect(find.byType(FightScreen), findsOneWidget);
  });

  testWidgets('Report opens an email with the log attached', (WidgetTester t) async {
    final Rigging r = await makeApp();
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
    await pumpApp(t, r);
    await openMenu(t, l);
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
    await pumpApp(t, r);
    await openMenu(t, l);
    await t.tap(find.bySemanticsLabel(l.homeSettings));
    await t.pump();
    await t.pump();
    final ModalRoute<dynamic> route = ModalRoute.of(t.element(find.byType(SettingsScreen)))!;
    expect(route.transitionDuration, Duration.zero);
    h.dispose();
  });

  testWidgets('the bout the app opens with plays to its end', (WidgetTester t) async {
    final Rigging r = await makeApp();
    await pumpApp(t, r);
    expect(find.byType(FightScreen), findsOneWidget);
    playOut(r.app);
    expect(r.app.fight.value!.finished, isTrue);
  });

  testWidgets('Settings opens the live privacy and support pages', (WidgetTester t) async {
    final SemanticsHandle h = t.ensureSemantics();
    final Rigging r = await makeApp();
    final List<String> opened = <String>[];
    await pumpApp(t, r, opened: opened);
    await openMenu(t, l);
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
