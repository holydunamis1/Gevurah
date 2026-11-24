import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/app/bootstrap.dart';
import 'package:gevurah/app/gevurah_app.dart';
import 'package:gevurah/l10n/app_localizations.dart';
import 'package:gevurah/platform/url_service.dart';
import 'package:gevurah/screens/home_screen.dart';
import 'package:gevurah/screens/onboarding_screen.dart';
import 'package:gevurah/screens/settings_screen.dart';

import '../screens/screens_test.dart' show Rigging, makeApp;

Future<void> noOrientation(List<DeviceOrientation> o) async {}

Future<void> pumpApp(WidgetTester t, Rigging r, {List<String>? opened}) async {
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
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> go(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
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
}
