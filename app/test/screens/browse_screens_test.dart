import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/progression_rules.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/l10n/app_localizations.dart';
import 'package:gevurah/l10n/l10n_helpers.dart';
import 'package:gevurah/screens/achievements_screen.dart';
import 'package:gevurah/screens/journey_map_screen.dart';
import 'package:gevurah/screens/mode_intro_screen.dart';
import 'package:gevurah/screens/modes_screen.dart';
import 'package:gevurah/screens/trials_screen.dart';

import 'screens_test.dart' show host, makeApp, Rigging;

Progress fresh() => Progress.initial(starterCardIds: CardCatalog.starterIds);

/// Career struggles 1..[count] overcome.
Progress wonCareer(int count, {int stars = 2, List<String> achievements = const <String>[]}) {
  return fresh().copyWith(
    bouts: <String, BoutRecord>{for (int i = 0; i < count; i++) StruggleCatalog.career[i].id: BoutRecord(stars: stars, wins: 1)},
    achievements: achievements,
  );
}

Future<void> tapText(WidgetTester t, String text) async {
  final Finder f = find.text(text);
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.tap(f);
}

Future<void> rendersEverywhere(WidgetTester t, Rigging r, Widget Function() screen) async {
  await t.pumpWidget(host(r.app, screen(), brightness: Brightness.dark));
  expect(t.takeException(), isNull);
  await t.pumpWidget(host(r.app, screen(), dir: TextDirection.rtl));
  expect(t.takeException(), isNull);
  await t.pumpWidget(host(r.app, screen(), scale: 2));
  expect(t.takeException(), isNull);
}

void main() {
  final AppLocalizations l = lookupAppLocalizations(const Locale('en'));
  final List<String> career = <String>[for (final s in StruggleCatalog.career) s.id];
  final List<String> trials = <String>[for (final s in StruggleCatalog.trials) s.id];

  group('JourneyMapScreen', () {
    testWidgets('a new player can open only the first struggle', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> opened = <String>[];
      await t.pumpWidget(host(r.app, JourneyMapScreen(onOpen: opened.add, onBack: () {})));
      expect(find.text('TIER 1'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      await t.tap(find.text('Fear'));
      expect(opened, <String>[career.first]);
      await t.tap(find.text('Worry'));
      expect(opened.length, 1);
    });

    testWidgets('overcome struggles show stars and a cleared tier is marked', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(4, stars: 3));
      await t.pumpWidget(host(r.app, JourneyMapScreen(onOpen: (String id) {}, onBack: () {})));
      expect(find.text('TIER 1 · TIER CLEARED'), findsOneWidget);
      expect(find.text('3 of 3 stars'), findsWidgets);
      expect(find.text('Overcome'), findsWidgets);
    });

    testWidgets('the final bout carries its name and opens last', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(career.length - 1));
      final List<String> opened = <String>[];
      await t.pumpWidget(host(r.app, JourneyMapScreen(onOpen: opened.add, onBack: () {})));
      final Finder finalRow = find.text('Still Standing · Ready');
      await t.scrollUntilVisible(finalRow, 300, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Giving Up'));
      expect(opened, <String>['giving_up']);
    });

    testWidgets('back works and every layout renders', (WidgetTester t) async {
      final Rigging r = await makeApp();
      int back = 0;
      await t.pumpWidget(host(r.app, JourneyMapScreen(onOpen: (String id) {}, onBack: () => back++)));
      await t.tap(find.bySemanticsLabel('Back'));
      expect(back, 1);
      await rendersEverywhere(t, r, () => JourneyMapScreen(onOpen: (String id) {}, onBack: () {}));
    });
  });

  group('TrialsScreen', () {
    testWidgets('are locked until tier 1 is cleared', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(3));
      await t.pumpWidget(host(r.app, TrialsScreen(onOpen: (String id) {}, onBack: () {})));
      expect(find.text('Clear tier 1 of the Journey to open the Trials.'), findsOneWidget);
    });

    testWidgets('open one at a time once tier 1 is cleared', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(4));
      final List<String> opened = <String>[];
      await t.pumpWidget(host(r.app, TrialsScreen(onOpen: opened.add, onBack: () {})));
      expect(find.text('Ready'), findsOneWidget);
      await tapText(t, l.struggleName(trials.first));
      expect(opened, <String>[trials.first]);
      await tapText(t, l.struggleName(trials[1]));
      expect(opened.length, 1);
      expect(ProgressionRules.unlocksFor(r.app.progress.value.progress).trialIdsOpen, <String>[trials.first]);
    });

    testWidgets('every layout renders', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(4));
      await rendersEverywhere(t, r, () => TrialsScreen(onOpen: (String id) {}, onBack: () {}));
      final Rigging locked = await makeApp();
      await rendersEverywhere(t, locked, () => TrialsScreen(onOpen: (String id) {}, onBack: () {}));
    });
  });

  group('ModesScreen', () {
    test('unlock rules match the progression rules', () {
      final Unlocks none = ProgressionRules.unlocksFor(fresh());
      expect(ModesScreen.isOpen(none, FightMode.journey), isTrue);
      expect(ModesScreen.isOpen(none, FightMode.daily), isTrue);
      expect(ModesScreen.isOpen(none, FightMode.training), isTrue);
      expect(ModesScreen.isOpen(none, FightMode.trials), isFalse);
      expect(ModesScreen.isOpen(none, FightMode.sparring), isFalse);
      expect(ModesScreen.isOpen(none, FightMode.endurance), isFalse);
      final Unlocks later = ProgressionRules.unlocksFor(wonCareer(8));
      for (final FightMode m in FightMode.values) {
        expect(ModesScreen.isOpen(later, m), isTrue, reason: '$m');
      }
      expect(ModesScreen.order.toSet(), FightMode.values.toSet());
    });

    testWidgets('open modes choose, locked modes explain how to open and do nothing', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<FightMode> chosen = <FightMode>[];
      await t.pumpWidget(host(r.app, ModesScreen(onChoose: chosen.add, onBack: () {})));
      expect(find.text('Clear tier 1 to open'), findsOneWidget);
      await tapText(t, 'One bout each day, the same for everyone.');
      await tapText(t, 'Learn each tell and the timing windows. No pressure and no stars.');
      expect(chosen, <FightMode>[FightMode.daily, FightMode.training]);
      await tapText(t, 'Clear tier 2 to open');
      expect(chosen.length, 2);
    });

    testWidgets('everything opens with progress', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(8));
      final List<FightMode> chosen = <FightMode>[];
      await t.pumpWidget(host(r.app, ModesScreen(onChoose: chosen.add, onBack: () {})));
      await tapText(t, 'Answer as many exchanges as you can as the pace rises.');
      expect(chosen, <FightMode>[FightMode.endurance]);
      expect(find.text('Clear tier 2 to open'), findsNothing);
    });

    testWidgets('every layout renders', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await rendersEverywhere(t, r, () => ModesScreen(onChoose: (FightMode m) {}, onBack: () {}));
    });
  });

  group('ModeIntroScreen', () {
    testWidgets('Sparring lists only struggles met and passes the difficulty', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(1));
      final List<String> log = <String>[];
      await t.pumpWidget(host(r.app, ModeIntroScreen(mode: FightMode.sparring, onChoose: (String? id, Difficulty d) => log.add('$id:${d.name}'), onBack: () {})));
      expect(find.text('Fear'), findsOneWidget);
      expect(find.text('Worry'), findsNothing);
      await t.tap(find.text('Hard'));
      await t.pump();
      await t.tap(find.text('Fear'));
      expect(log, <String>['fear:hard']);
    });

    testWidgets('Sparring with nothing met says so', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, ModeIntroScreen(mode: FightMode.sparring, onChoose: (String? id, Difficulty d) {}, onBack: () {})));
      expect(find.text('Win a bout to rematch it here.'), findsOneWidget);
    });

    testWidgets('Training offers every struggle at standard difficulty', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(host(r.app, ModeIntroScreen(mode: FightMode.training, onChoose: (String? id, Difficulty d) => log.add('$id:${d.name}'), onBack: () {})));
      expect(find.text('DIFFICULTY'), findsNothing);
      await tapText(t, 'Procrastination');
      expect(log, <String>['procrastination:standard']);
    });

    testWidgets('Endurance starts only once it is open', (WidgetTester t) async {
      final List<String?> log = <String?>[];
      final Rigging locked = await makeApp();
      await t.pumpWidget(host(locked.app, ModeIntroScreen(mode: FightMode.endurance, onChoose: (String? id, Difficulty d) => log.add(id), onBack: () {})));
      await t.tap(find.text('Start'), warnIfMissed: false);
      expect(log, isEmpty);
      final Rigging open = await makeApp(progress: wonCareer(8));
      await t.pumpWidget(host(open.app, ModeIntroScreen(mode: FightMode.endurance, onChoose: (String? id, Difficulty d) => log.add(id), onBack: () {})));
      await t.tap(find.text('Start'));
      expect(log, <String?>[null]);
    });

    testWidgets('every layout renders for every mode', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(8));
      for (final FightMode m in <FightMode>[FightMode.sparring, FightMode.training, FightMode.endurance]) {
        await rendersEverywhere(t, r, () => ModeIntroScreen(mode: m, onChoose: (String? id, Difficulty d) {}, onBack: () {}));
      }
    });
  });

  group('AchievementsScreen', () {
    testWidgets('counts what is unlocked and names each milestone', (WidgetTester t) async {
      final Rigging r = await makeApp(progress: wonCareer(4, achievements: <String>['first_win', 'tier_1']));
      await t.pumpWidget(host(r.app, AchievementsScreen(onBack: () {})));
      expect(find.text('2 of 15'), findsOneWidget);
      expect(find.text('First bout won'), findsOneWidget);
      expect(find.text('Win a bout.'), findsOneWidget);
      expect(find.text('Unlocked'), findsWidgets);
      await t.scrollUntilVisible(find.text('A full week'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Locked'), findsWidgets);
    });

    testWidgets('a new player has none and every layout renders', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, AchievementsScreen(onBack: () {})));
      expect(find.text('0 of 15'), findsOneWidget);
      await rendersEverywhere(t, r, () => AchievementsScreen(onBack: () {}));
    });
  });
}
