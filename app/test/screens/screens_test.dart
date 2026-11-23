import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/config/remote_flags.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/storage/progress_codec.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/core/ports/consent_port.dart';
import 'package:gevurah/core/verses/verse_repository.dart';
import 'package:gevurah/l10n/app_localizations.dart';
import 'package:gevurah/providers/app_providers.dart';
import 'package:gevurah/providers/app_scope.dart';
import 'package:gevurah/screens/card_picker_screen.dart';
import 'package:gevurah/screens/corner_screen.dart';
import 'package:gevurah/screens/fight_screen.dart';
import 'package:gevurah/screens/home_screen.dart';
import 'package:gevurah/screens/opponent_card_screen.dart';
import 'package:gevurah/screens/result_screen.dart';
import 'package:gevurah/screens/ten_count_screen.dart';
import 'package:gevurah/theme/app_theme.dart';

import '../fakes/fakes.dart';

Future<String> fromDisk(String path) async => File(path).readAsStringSync();

class Rigging {
  Rigging(this.app, this.storage, this.ads);

  final AppProviders app;
  final FakeStorage storage;
  final FakeAds ads;
}

Future<Rigging> makeApp({FakeStorage? storage, Progress? progress}) async {
  final FakeStorage s = storage ?? FakeStorage();
  if (progress != null) {
    s.files[ProgressStore.mainFile] = ProgressCodec.encode(progress);
  }
  final FakeAds ads = FakeAds();
  final AppProviders app = AppProviders.create(
    storage: s,
    clock: FakeClock(DateTime(2026, 11, 22, 9)),
    billing: FakeBilling(),
    consent: FakeConsent(const ConsentState(canRequestAds: true, privacyOptionsRequired: false)),
    ads: ads,
    notifications: FakeNotifications(),
    verseRepository: VerseRepository(fromDisk),
    fetchFlags: () async => RemoteFlags.defaults,
    deviceLanguages: <String>['en'],
    haptics: FakeHaptics(),
    audio: FakeAudio(),
  );
  await app.startUp();
  return Rigging(app, s, ads);
}

Widget host(
  AppProviders app,
  Widget child, {
  TextDirection dir = TextDirection.ltr,
  double scale = 1,
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 720),
}) {
  return AppScope(
    providers: app,
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: dir,
        child: Localizations(
          locale: Locale('en'),
          delegates: const <LocalizationsDelegate<dynamic>>[AppLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
          child: AppTheme.forBrightness(
            brightness: brightness,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Navigator(
                  onGenerateRoute: (RouteSettings s) => PageRouteBuilder<void>(pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) => child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

FightConfig journeyConfig(String id) => FightConfig(
      mode: FightMode.journey,
      struggleId: id,
      cardIds: const <String>[],
      stance: Stance.steady,
      seed: 5,
    );

/// Plays a started bout to its end with perfect guards.
void playOut(AppProviders app) {
  for (int i = 0; i < 600 && !app.fight.value!.finished; i++) {
    final FightState s = app.fight.value!.state;
    if (s.phase == FightPhase.corner) {
      app.fight.endCorner();
    } else if (s.phase == FightPhase.tenCount) {
      app.fight.rise(3);
    } else {
      app.fight.respond(response: Response.guard, offset: const BeatOffset(0));
    }
  }
}

/// Lets a route transition start and finish.
Future<void> settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(seconds: 1));
}

class Clock {
  double now = 0;
  double read() => now;
}

void main() {
  final String first = StruggleCatalog.career.first.id;
  final String second = StruggleCatalog.career[1].id;

  group('HomeScreen', () {
    Widget home(AppProviders app, List<String> log, {TextDirection dir = TextDirection.ltr, double scale = 1, Brightness b = Brightness.light}) {
      return host(
        app,
        HomeScreen(
          onContinue: (String id) => log.add('continue:$id'),
          onJourney: () => log.add('journey'),
          onDaily: () => log.add('daily'),
          onModes: () => log.add('modes'),
          onCards: () => log.add('cards'),
          onLibrary: () => log.add('library'),
          onSettings: () => log.add('settings'),
        ),
        dir: dir,
        scale: scale,
        brightness: b,
      );
    }

    testWidgets('continue starts the first struggle and every card navigates', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(home(r.app, log));
      expect(find.text('Continue'), findsOneWidget);
      expect(find.textContaining('Next:'), findsOneWidget);
      await t.tap(find.text('Continue'));
      await t.tap(find.text('Journey'));
      await t.tap(find.text('Daily Bout'));
      await t.tap(find.text('Modes'));
      await t.tap(find.text('Cards'));
      await t.tap(find.text('Verse library'));
      await t.tap(find.bySemanticsLabel('Settings'));
      expect(log, <String>['continue:$first', 'journey', 'daily', 'modes', 'cards', 'library', 'settings']);
      expect(HomeScreen.nextStruggle(r.app.progress.value.progress), first);
    });

    testWidgets('a failed save shows a warning with a retry', (WidgetTester t) async {
      final FakeStorage s = FakeStorage();
      final Rigging r = await makeApp(storage: s);
      await t.pumpWidget(home(r.app, <String>[]));
      expect(find.text('Your progress could not be saved.'), findsNothing);
      s.failWrites = true;
      await r.app.loadout.equip(CardCatalog.starterIds.first);
      await t.pump();
      expect(find.text('Your progress could not be saved.'), findsOneWidget);
      s.failWrites = false;
      await t.tap(find.text('Try again'));
      await t.pump();
      await t.pump();
      expect(find.text('Your progress could not be saved.'), findsNothing);
    });

    testWidgets('renders in dark, right-to-left and large text without overflow', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(home(r.app, <String>[], b: Brightness.dark));
      expect(t.takeException(), isNull);
      await t.pumpWidget(home(r.app, <String>[], dir: TextDirection.rtl));
      expect(t.takeException(), isNull);
      await t.pumpWidget(home(r.app, <String>[], scale: 2));
      expect(t.takeException(), isNull);
    });
  });

  group('OpponentCardScreen', () {
    Widget opponent(AppProviders app, String id, List<String> log, {double scale = 1, TextDirection dir = TextDirection.ltr}) {
      return host(
        app,
        OpponentCardScreen(
          struggleId: id,
          mode: FightMode.journey,
          onStart: () => log.add('start'),
          onChangeCards: () => log.add('cards'),
          onBack: () => log.add('back'),
        ),
        scale: scale,
        dir: dir,
      );
    }

    testWidgets('shows the struggle, its tell and a verse, and starts the bout', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(opponent(r.app, first, log));
      await t.pump();
      await t.pump();
      expect(find.text('Start bout'), findsOneWidget);
      expect(find.text('Tier 1'), findsOneWidget);
      await t.tap(find.text('Start bout'));
      expect(log, <String>['start']);
      expect(r.app.fight.value, isNotNull);
      expect(r.app.fight.value!.struggle.id, first);
      expect(r.app.fight.value!.config.mode, FightMode.journey);
      await t.scrollUntilVisible(find.text('Change cards'), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.text('Change cards'));
      await t.tap(find.bySemanticsLabel('Back'));
      expect(log, <String>['start', 'cards', 'back']);
    });

    testWidgets('a struggle that is not open cannot be started', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final List<String> log = <String>[];
      await t.pumpWidget(opponent(r.app, second, log));
      await t.tap(find.text('Start bout'), warnIfMissed: false);
      expect(log, isEmpty);
      expect(r.app.fight.value, isNull);
    });

    testWidgets('equipped cards are listed and large text and right-to-left render', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await r.app.loadout.equip(CardCatalog.starterIds.first);
      await t.pumpWidget(opponent(r.app, first, <String>[], scale: 2));
      expect(find.text('No cards equipped'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(opponent(r.app, first, <String>[], dir: TextDirection.rtl));
      expect(t.takeException(), isNull);
    });
  });

  group('CardPickerScreen', () {
    testWidgets('equips and unequips cards, at most three, and sets the stance', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, CardPickerScreen(onBack: () {})));
      final int owned = r.app.loadout.value.earned.length;
      expect(owned, CardCatalog.starterIds.length);
      for (final String id in CardCatalog.starterIds) {
        await r.app.loadout.toggle(id);
      }
      await t.pump();
      expect(r.app.loadout.value.loadout.cardIds.length, owned < 3 ? owned : 3);
      if (owned > 3) {
        expect(find.text('Three cards are equipped. Remove one to add another.'), findsOneWidget);
      }
      final String firstEquipped = r.app.loadout.value.loadout.cardIds.first;
      await r.app.loadout.unequip(firstEquipped);
      await t.pump();
      expect(r.app.loadout.value.isEquipped(firstEquipped), isFalse);
      await t.tap(find.text('Bold'));
      await t.pump();
      expect(r.app.loadout.value.loadout.stance, Stance.bold);
      expect(t.takeException(), isNull);
    });

    testWidgets('dark, right-to-left and large text render', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, CardPickerScreen(onBack: () {}), brightness: Brightness.dark, scale: 2));
      expect(t.takeException(), isNull);
      await t.pumpWidget(host(r.app, CardPickerScreen(onBack: () {}), dir: TextDirection.rtl));
      expect(t.takeException(), isNull);
    });
  });

  group('CornerScreen', () {
    Widget corner(AppProviders app, {int round = 2, Stance stance = Stance.steady, ValueChanged<Stance>? onStance, VoidCallback? onNext, Size size = const Size(360, 720), double scale = 1, TextDirection dir = TextDirection.ltr}) {
      return host(app, CornerScreen(round: round, stance: stance, onStance: onStance ?? (Stance s) {}, onNextRound: onNext ?? () {}), size: size, scale: scale, dir: dir);
    }

    testWidgets('names the round, shows a verse and a stance choice and moves on', (WidgetTester t) async {
      final Rigging r = await makeApp();
      int next = 0;
      final List<Stance> picked = <Stance>[];
      await t.pumpWidget(corner(r.app, onStance: picked.add, onNext: () => next++));
      await t.pump();
      await t.pump();
      expect(find.text('Round 2 complete'), findsOneWidget);
      expect(find.text('Stamina restored'), findsOneWidget);
      await t.tap(find.text('Bold'));
      expect(picked, <Stance>[Stance.bold]);
      await t.tap(find.text('Next round'));
      expect(next, 1);
    });

    testWidgets('portrait, landscape, large text and right-to-left all fit', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(corner(r.app, scale: 2, dir: TextDirection.rtl));
      await t.pump();
      expect(t.takeException(), isNull);
      await t.pumpWidget(corner(r.app, size: const Size(740, 360)));
      await t.pump();
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Next round'), findsOneWidget);
      await t.pumpWidget(corner(r.app, size: const Size(740, 360), scale: 1.5));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('TenCountScreen', () {
    test('steadiness is a rhythm between the minimum and maximum gap', () {
      expect(TenCountScreen.isSteady(100), isFalse);
      expect(TenCountScreen.isSteady(250), isTrue);
      expect(TenCountScreen.isSteady(600), isTrue);
      expect(TenCountScreen.isSteady(900), isTrue);
      expect(TenCountScreen.isSteady(901), isFalse);
    });

    testWidgets('steady taps all count and the bout rises after the target', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final Clock clock = Clock();
      final List<int> rose = <int>[];
      await t.pumpWidget(host(r.app, TenCountScreen(onRise: rose.add, nowMs: clock.read)));
      for (int i = 0; i < TenCountScreen.targetTaps; i++) {
        clock.now += 500;
        await t.tap(find.text('Tap'));
        await t.pump();
      }
      expect(rose, <int>[TenCountScreen.targetTaps]);
    });

    testWidgets('rushed taps do not count', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final Clock clock = Clock();
      final List<int> rose = <int>[];
      await t.pumpWidget(host(r.app, TenCountScreen(onRise: rose.add, nowMs: clock.read)));
      for (int i = 0; i < TenCountScreen.targetTaps; i++) {
        clock.now += 50;
        await t.tap(find.text('Tap'));
        await t.pump();
      }
      expect(rose, <int>[1]);
    });

    testWidgets('fits in landscape and with large text', (WidgetTester t) async {
      final Rigging r = await makeApp();
      await t.pumpWidget(host(r.app, TenCountScreen(onRise: (int n) {}), size: const Size(740, 360)));
      await t.pump();
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Tap'), findsOneWidget);
      await t.pumpWidget(host(r.app, TenCountScreen(onRise: (int n) {}), size: const Size(740, 360), scale: 1.5));
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('Stand up and the time limit end it once with the good taps so far', (WidgetTester t) async {
      final Rigging r = await makeApp();
      final Clock clock = Clock();
      final List<int> rose = <int>[];
      await t.pumpWidget(host(r.app, TenCountScreen(onRise: rose.add, nowMs: clock.read, limit: const Duration(seconds: 2))));
      clock.now += 400;
      await t.tap(find.text('Tap'));
      await t.pump(const Duration(seconds: 3));
      expect(rose, <int>[1]);
      await t.tap(find.text('Stand up'), warnIfMissed: false);
      expect(rose, <int>[1]);
    });
  });

  group('ResultScreen', () {
    Widget result(AppProviders app, List<String> log, {double scale = 1, TextDirection dir = TextDirection.ltr, Brightness b = Brightness.light}) {
      return host(
        app,
        ResultScreen(onContinue: () => log.add('continue'), onTryAgain: () => log.add('again'), onHome: () => log.add('home')),
        scale: scale,
        dir: dir,
        brightness: b,
      );
    }

    testWidgets('records the bout once, shows the outcome and offers one interstitial', (WidgetTester t) async {
      final Rigging r = await makeApp();
      expect(r.app.fight.start(journeyConfig(first)), isTrue);
      playOut(r.app);
      final List<String> log = <String>[];
      await t.pumpWidget(result(r.app, log));
      await t.pump();
      await t.pump();
      await t.pump();
      final bool won = r.app.fight.value!.won;
      expect(find.text(won ? 'You stood firm' : 'Not this time'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(r.ads.interstitialsShown, r.app.ads.interstitialAllowed ? 1 : 0);
      if (won) {
        expect(r.app.progress.value.progress.bouts[first]?.wins, 1);
      }
      await t.tap(find.text('Continue'));
      await t.tap(find.text('Try again'));
      await t.tap(find.text('Home'));
      expect(log, <String>['continue', 'again', 'home']);
      await t.pumpWidget(result(r.app, log));
      await t.pump();
      expect(r.app.progress.value.progress.bouts[first]?.wins, won ? 1 : null);
    });

    testWidgets('an Endurance run shows the exchanges answered and the best run', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.app.fight.start(const FightConfig(mode: FightMode.endurance, struggleId: 'giving_up', cardIds: <String>[], stance: Stance.steady, seed: 3));
      for (int i = 0; i < 2000 && !r.app.fight.value!.finished; i++) {
        final FightState s = r.app.fight.value!.state;
        if (s.phase == FightPhase.corner) {
          r.app.fight.endCorner();
        } else if (s.phase == FightPhase.tenCount) {
          r.app.fight.rise(0);
        } else {
          r.app.fight.respond(response: Response.takeIt, offset: const BeatOffset(0));
        }
      }
      await t.pumpWidget(result(r.app, <String>[]));
      await t.pump();
      await t.pump();
      await t.pump();
      expect(find.textContaining('answered'), findsOneWidget);
      expect(find.textContaining('Best:'), findsOneWidget);
      expect(find.text('New best'), findsOneWidget);
      expect(find.textContaining('stars'), findsNothing);
    });

    testWidgets('dark, right-to-left and large text render', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.app.fight.start(journeyConfig(first));
      playOut(r.app);
      await t.pumpWidget(result(r.app, <String>[], b: Brightness.dark, scale: 2));
      await t.pump();
      await t.pump();
      expect(t.takeException(), isNull);
      await t.pumpWidget(result(r.app, <String>[], dir: TextDirection.rtl));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('FightScreen', () {
    testWidgets('asks for landscape while it is open and portrait when it closes', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.app.fight.start(journeyConfig(first));
      final List<List<DeviceOrientation>> asked = <List<DeviceOrientation>>[];
      Future<void> record(List<DeviceOrientation> o) async => asked.add(o);
      await t.pumpWidget(host(r.app, FightScreen(onFinished: () {}, onLeave: () {}, setOrientations: record), size: const Size(740, 360)));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
      expect(asked, <List<DeviceOrientation>>[FightScreen.fightOrientations]);
      expect(t.takeException(), isNull);
      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      expect(asked.last, FightScreen.menuOrientations);
    });

    testWidgets('pause offers resume, and leaving asks first then records nothing', (WidgetTester t) async {
      final Rigging r = await makeApp();
      r.app.fight.start(journeyConfig(first));
      int left = 0;
      int finished = 0;
      await t.pumpWidget(host(r.app, FightScreen(onFinished: () => finished++, onLeave: () => left++, setOrientations: (List<DeviceOrientation> o) async {})));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.bySemanticsLabel('Pause'));
      await settle(t);
      expect(find.text('Paused'), findsOneWidget);
      await t.tap(find.text('Resume'));
      await settle(t);
      expect(find.text('Paused'), findsNothing);
      await t.tap(find.bySemanticsLabel('Pause'));
      await settle(t);
      await t.tap(find.text('Leave bout'));
      await settle(t);
      expect(find.text('Leave this bout?'), findsOneWidget);
      await t.tap(find.text('Keep fighting'));
      await settle(t);
      expect(left, 0);
      expect(r.app.fight.value, isNotNull);
      await t.tap(find.bySemanticsLabel('Pause'));
      await settle(t);
      await t.tap(find.text('Leave bout'));
      await settle(t);
      await t.tap(find.text('Leave bout'));
      await settle(t);
      expect(left, 1);
      expect(finished, 0);
      expect(r.app.fight.value, isNull);
      expect(r.app.progress.value.progress.bouts, isEmpty);
      await t.pumpWidget(const SizedBox());
    });
  });
}
