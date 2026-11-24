import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/models/license_notice.dart';
import 'package:gevurah/core/models/settings_model.dart';
import 'package:gevurah/core/ports/billing_port.dart';
import 'package:gevurah/core/ports/consent_port.dart';
import 'package:gevurah/screens/error_screen.dart';
import 'package:gevurah/screens/licenses_screen.dart';
import 'package:gevurah/screens/onboarding_screen.dart';
import 'package:gevurah/screens/settings_screen.dart';
import 'package:gevurah/screens/upgrade_screen.dart';

import '../fakes/fakes.dart';
import 'screens_test.dart' show Rigging, host, makeApp, settle;

Future<void> tapText(WidgetTester t, String text) async {
  final Finder f = find.text(text);
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
}

SettingsScreen settingsScreen(List<String> log) => SettingsScreen(
      onBack: () => log.add('back'),
      onAchievements: () => log.add('achievements'),
      onUpgrade: () => log.add('upgrade'),
      onSupport: () => log.add('support'),
      onPrivacyPolicy: () => log.add('privacy'),
      onLicenses: () => log.add('licenses'),
    );

Future<void> rendersEverywhere(WidgetTester t, Rigging r, Widget Function() screen) async {
  await t.pumpWidget(host(r.app, screen(), brightness: Brightness.dark));
  await t.pump();
  expect(t.takeException(), isNull);
  await t.pumpWidget(host(r.app, screen(), dir: TextDirection.rtl));
  await t.pump();
  expect(t.takeException(), isNull);
  await t.pumpWidget(host(r.app, screen(), scale: 2));
  await t.pump();
  expect(t.takeException(), isNull);
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('Play records that onboarding is done and moves on', (WidgetTester t) async {
      final Rigging r = await makeApp();
      int done = 0;
      await t.pumpWidget(host(r.app, OnboardingScreen(onDone: () => done++)));
      await t.pump();
      expect(r.app.settings.settings.onboardingDone, isFalse);
      await t.tap(find.text('Play'));
      await t.pump();
      expect(r.app.settings.settings.onboardingDone, isTrue);
      expect(done, 1);
    });

    testWidgets('choosing a language is saved', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, OnboardingScreen(onDone: () {})));
      await t.pump();
      await tapText(t, 'Español');
      await t.pump();
      expect(r.app.settings.settings.localeCode, 'es');
    });

    testWidgets('renders in dark, right-to-left and large text', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await rendersEverywhere(t, r, () => OnboardingScreen(onDone: () {}));
    });
  });

  group('SettingsScreen', () {
    testWidgets('Restore purchase is always visible, and the privacy row only when required', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, settingsScreen(<String>[])));
      await t.pump();
      await t.scrollUntilVisible(find.text('Restore purchase'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Restore purchase'), findsOneWidget);
      expect(find.text('Privacy choices'), findsNothing);
    });

    testWidgets('the privacy row shows when consent says it is required', (WidgetTester t) async {
      final Rigging r = await makeApp(consent: FakeConsent(const ConsentState(canRequestAds: true, privacyOptionsRequired: true)));
      await t.pumpWidget(host(r.app, settingsScreen(<String>[])));
      await t.pump();
      await t.scrollUntilVisible(find.text('Privacy choices'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Privacy choices'), findsOneWidget);
    });

    testWidgets('theme choice is saved', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, settingsScreen(<String>[])));
      await t.pump();
      await t.tap(find.text('Dark'));
      await t.pump();
      expect(r.app.settings.settings.themeChoice, ThemeChoice.dark);
    });

    testWidgets('toggles are saved', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final bool before = r.app.settings.settings.soundOn;
      await t.pumpWidget(host(r.app, settingsScreen(<String>[])));
      await t.pump();
      await tapText(t, 'Sound effects');
      await t.pump();
      expect(r.app.settings.settings.soundOn, !before);
    });

    testWidgets('language opens a sheet; Phone\'s language clears the choice', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await r.app.locale.choose('fr');
      await t.pumpWidget(host(r.app, settingsScreen(<String>[])));
      await t.pump();
      await t.tap(find.text('Français'));
      await settle(t);
      await t.tap(find.text("Phone's language").last);
      await settle(t);
      expect(r.app.settings.settings.localeCode, isNull);
    });

    testWidgets('rows call their callbacks', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(host(r.app, settingsScreen(log)));
      await t.pump();
      await tapText(t, 'Remove Ads');
      await tapText(t, 'Contact support');
      await tapText(t, 'Privacy policy');
      await tapText(t, 'Licenses');
      expect(log, <String>['upgrade', 'support', 'privacy', 'licenses']);
    });

    testWidgets('Restore reports its result', (WidgetTester t) async {
      final FakeBilling billing = FakeBilling();
      final Rigging r = await makeApp(billing: billing);
      await t.pumpWidget(host(r.app, settingsScreen(<String>[])));
      await t.pump();
      await tapText(t, 'Restore purchase');
      await t.pump();
      await t.pump();
      expect(r.app.entitlement.value.lastOutcome, PurchaseOutcome.nothingToRestore);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders in dark, right-to-left and large text', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await rendersEverywhere(t, r, () => settingsScreen(<String>[]));
    });
  });

  group('UpgradeScreen', () {
    testWidgets('Buy shows the price and completes the purchase', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, UpgradeScreen(onBack: () {})));
      await t.pump();
      expect(find.textContaining(r'$2.99'), findsOneWidget);
      await t.tap(find.textContaining(r'$2.99'));
      await t.pump();
      await t.pump();
      expect(r.app.entitlement.value.adsRemoved, isTrue);
    });

    testWidgets('Buy is disabled when the store is unavailable', (WidgetTester t) async {
      final FakeBilling billing = FakeBilling()..available = false;
      final Rigging r = await makeApp(billing: billing);
      await t.pumpWidget(host(r.app, UpgradeScreen(onBack: () {})));
      await t.pump();
      await t.tap(find.text('Remove Ads').last);
      await t.pump();
      expect(r.app.entitlement.value.adsRemoved, isFalse);
    });

    testWidgets('an owned purchase shows the badge instead of Buy', (WidgetTester t) async {
      final FakeBilling billing = FakeBilling()..entitlement = Entitlement.adsRemoved;
      final Rigging r = await makeApp(billing: billing);
      await t.pumpWidget(host(r.app, UpgradeScreen(onBack: () {})));
      await t.pump();
      expect(find.text('Ads removed'), findsWidgets);
      expect(find.textContaining(r'$2.99'), findsNothing);
    });

    testWidgets('renders in dark, right-to-left and large text', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await rendersEverywhere(t, r, () => UpgradeScreen(onBack: () {}));
    });
  });

  group('LicensesScreen', () {
    testWidgets('shows every notice with its attribution and opens its link', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> opened = <String>[];
      await t.pumpWidget(host(r.app, LicensesScreen(loadNotices: r.app.verses.notices, onOpenLink: opened.add, onBack: () {})));
      await t.pump();
      await t.pump();
      final List<LicenseNotice> notices = await r.app.verses.notices();
      expect(notices, isNotEmpty);
      expect(find.text(notices.first.sourceName), findsWidgets);
      await t.tap(find.text('Open license page').first);
      expect(opened, <String>[notices.first.link]);
    });

    testWidgets('an empty list shows the empty state', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, LicensesScreen(loadNotices: () async => <LicenseNotice>[], onOpenLink: (String _) {}, onBack: () {})));
      await t.pump();
      await t.pump();
      expect(find.text('No notices could be loaded.'), findsOneWidget);
    });

    testWidgets('renders in dark, right-to-left and large text', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await rendersEverywhere(t, r, () => LicensesScreen(loadNotices: r.app.verses.notices, onOpenLink: (String _) {}, onBack: () {}));
    });
  });

  group('ErrorScreen', () {
    testWidgets('offers Retry and report', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(host(r.app, ErrorScreen(onRetry: () => log.add('retry'), onReport: () => log.add('report'))));
      await t.pump();
      await t.tap(find.text('Try again'));
      await t.tap(find.text('Send a report'));
      expect(log, <String>['retry', 'report']);
    });
  });
}
