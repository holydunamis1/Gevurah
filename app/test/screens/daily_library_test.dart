import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/config/remote_flags.dart';
import 'package:gevurah/core/logic/daily_seed.dart';
import 'package:gevurah/core/models/daily_challenge.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/screens/daily_bout_screen.dart';
import 'package:gevurah/screens/verse_library_screen.dart';
import 'package:gevurah/widgets/verse_card.dart';

import 'screens_test.dart' show Rigging, host, makeApp;

Progress fresh() => Progress.initial(starterCardIds: CardCatalog.starterIds);

Future<void> tapText(WidgetTester t, String text) async {
  final Finder f = find.text(text);
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
}

Future<void> settleVerses(WidgetTester t) async {
  await t.pump();
  await t.pump();
  await t.pump();
}

Future<void> rendersEverywhere(WidgetTester t, Rigging r, Widget Function() screen) async {
  await t.pumpWidget(host(r.app, screen(), brightness: Brightness.dark));
  await settleVerses(t);
  expect(t.takeException(), isNull);
  await t.pumpWidget(host(r.app, screen(), dir: TextDirection.rtl));
  await settleVerses(t);
  expect(t.takeException(), isNull);
  await t.pumpWidget(host(r.app, screen(), scale: 2));
  await settleVerses(t);
  expect(t.takeException(), isNull);
}

void main() {
  final String today = DailySeed.dateKey(DateTime(2026, 11, 22, 9));

  group('VerseLibraryScreen', () {
    testWidgets('the Cards tab shows the verses on the cards earned', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, VerseLibraryScreen(onBack: () {})));
      await settleVerses(t);
      expect(find.byType(VerseCard), findsWidgets);
      expect(find.text('Cards'), findsOneWidget);
    });

    testWidgets('the Struggles tab shows only struggles met, with their names', (WidgetTester t) async {
      final Rigging none = await makeApp();
      await t.pumpWidget(host(none.app, VerseLibraryScreen(onBack: () {})));
      await t.tap(find.text('Struggles'));
      await settleVerses(t);
      expect(find.text('Meet a struggle in the Journey to read its verse here.'), findsOneWidget);
      expect(find.byType(VerseCard), findsNothing);

      final Rigging met = await makeApp(progress: fresh().copyWith(bouts: <String, BoutRecord>{'fear': const BoutRecord(stars: 1, wins: 1)}));
      await t.pumpWidget(host(met.app, VerseLibraryScreen(onBack: () {})));
      await t.tap(find.text('Struggles'));
      await settleVerses(t);
      expect(find.text('Fear'), findsOneWidget);
      expect(find.byType(VerseCard), findsOneWidget);
    });

    testWidgets('the Moments tab lists the shared verses by moment', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, VerseLibraryScreen(onBack: () {})));
      await t.tap(find.text('Moments'));
      await settleVerses(t);
      expect(find.text('BETWEEN ROUNDS'), findsOneWidget);
      expect(find.byType(VerseCard), findsWidgets);
      await t.scrollUntilVisible(find.text('DAILY VERSES'), 400, scrollable: find.byType(Scrollable).first, maxScrolls: 200);
      expect(find.text('DAILY VERSES'), findsOneWidget);
    });

    testWidgets('back works and every layout renders', (WidgetTester t) async {
      final Rigging r = await makeApp();
      int back = 0;
      await t.pumpWidget(host(r.app, VerseLibraryScreen(onBack: () => back++)));
      await t.tap(find.bySemanticsLabel('Back'));
      expect(back, 1);
      await rendersEverywhere(t, r, () => VerseLibraryScreen(onBack: () {}));
    });
  });

  group('DailyBoutScreen', () {
    testWidgets("shows today's struggle and starts the bout with today's challenge", (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<DailyChallenge> started = <DailyChallenge>[];
      await t.pumpWidget(host(r.app, DailyBoutScreen(onStart: started.add, onBack: () {})));
      await settleVerses(t);
      expect(find.text("Today's struggle"), findsOneWidget);
      await t.tap(find.text('Start bout'));
      expect(started, <DailyChallenge>[r.app.daily.value.challenge]);
      expect(started.single.dateKey, today);
    });

    testWidgets('a finished day shows stars and cannot be started again', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: fresh().copyWith(dailyHistory: <DailyRecord>[DailyRecord(dateKey: today, completed: true, stars: 2)]));
      final List<DailyChallenge> started = <DailyChallenge>[];
      await t.pumpWidget(host(r.app, DailyBoutScreen(onStart: started.add, onBack: () {})));
      await settleVerses(t);
      expect(find.text('Done for today. Come back tomorrow.'), findsOneWidget);
      expect(find.text('2 of 3 stars'), findsOneWidget);
      expect(find.text('1-day streak'), findsOneWidget);
      await t.tap(find.text('Start bout'), warnIfMissed: false);
      expect(started, isEmpty);
    });

    testWidgets('the reminder asks permission only when turned on, then schedules and lets the time change', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, DailyBoutScreen(onStart: (DailyChallenge c) {}, onBack: () {})));
      await settleVerses(t);
      expect(r.notifications.scheduledMinute, isNull);
      expect(find.text('Reminder time'), findsNothing);
      await tapText(t, 'Remind me each day');
      await settleVerses(t);
      expect(r.app.settings.settings.remindersOn, isTrue);
      expect(r.notifications.scheduledMinute, r.app.settings.settings.reminderMinuteOfDay);
      expect(r.notifications.scheduledTitle, 'Daily Bout');
      await tapText(t, 'Reminder time');
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(seconds: 1));
      await t.ensureVisible(find.text('18:00'));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.text('18:00'));
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(seconds: 1));
      expect(r.notifications.scheduledMinute, 18 * 60);
      expect(r.app.settings.settings.reminderMinuteOfDay, 18 * 60);
    });

    testWidgets('a refused permission leaves the reminder off and says so', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.notifications.grantOnRequest = false;
      await t.pumpWidget(host(r.app, DailyBoutScreen(onStart: (DailyChallenge c) {}, onBack: () {})));
      await settleVerses(t);
      await tapText(t, 'Remind me each day');
      await settleVerses(t);
      expect(r.app.settings.settings.remindersOn, isFalse);
      expect(r.notifications.scheduledMinute, isNull);
      expect(find.textContaining('Notifications are turned off'), findsOneWidget);
    });

    testWidgets('a switched-off Daily Bout says so', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.app.flags.value = const RemoteFlags(dailyBoutEnabled: false);
      await t.pumpWidget(host(r.app, DailyBoutScreen(onStart: (DailyChallenge c) {}, onBack: () {})));
      expect(find.text('The Daily Bout is not available right now.'), findsOneWidget);
    });

    testWidgets('every layout renders', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await rendersEverywhere(t, r, () => DailyBoutScreen(onStart: (DailyChallenge c) {}, onBack: () {}));
    });
  });
}
