import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/loadout.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/settings_model.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/ports/billing_port.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/providers/entitlement_provider.dart';
import 'package:gevurah/providers/loadout_provider.dart';
import 'package:gevurah/providers/locale_provider.dart';
import 'package:gevurah/providers/progress_provider.dart';
import 'package:gevurah/providers/settings_provider.dart';
import 'package:gevurah/providers/theme_provider.dart';

import '../fakes/fakes.dart';

FightState won() => const FightState(
      round: 3,
      startingWeight: 100,
      weight: 0,
      player: PlayerState(resolve: 80, stamina: 50, downs: 0, breathCharges: 0),
      exchangeIndex: 40,
      phase: FightPhase.finished,
      end: FightEnd.struggleDefeated,
    );

ProgressProvider newProgress(FakeStorage s) =>
    ProgressProvider(ProgressStore(s, starterCardIds: CardCatalog.starterIds));

void main() {
  group('settings, theme and locale', () {
    test('load defaults, change, persist and reload', () async {
      final FakeStorage storage = FakeStorage();
      final SettingsProvider a = SettingsProvider(storage);
      expect(a.value.loaded, isFalse);
      await a.load();
      expect(a.value.loaded, isTrue);
      expect(await a.update((SettingsModel s) => s.copyWith(soundOn: false)), isTrue);
      final SettingsProvider b = SettingsProvider(storage);
      await b.load();
      expect(b.settings.soundOn, isFalse);
    });

    test('a failed save keeps the change and flags it, then recovers', () async {
      final FakeStorage storage = FakeStorage();
      final SettingsProvider p = SettingsProvider(storage);
      await p.load();
      storage.failWrites = true;
      expect(await p.update((SettingsModel s) => s.copyWith(hapticsOn: false)), isFalse);
      expect(p.value.saveFailed, isTrue);
      expect(p.settings.hapticsOn, isFalse);
      storage.failWrites = false;
      expect(await p.update((SettingsModel s) => s.copyWith(musicOn: false)), isTrue);
      expect(p.value.saveFailed, isFalse);
    });

    test('unreadable storage gives defaults', () async {
      final FakeStorage storage = FakeStorage()..failReads = true;
      final SettingsProvider p = SettingsProvider(storage);
      await p.load();
      expect(p.value.loaded, isTrue);
      expect(p.settings, const SettingsModel());
    });

    test('state equality', () {
      expect(const SettingsState(), const SettingsState());
      expect(const SettingsState().hashCode, const SettingsState().hashCode);
      expect(const SettingsState(), isNot(const SettingsState(loaded: true)));
    });

    test('theme follows settings and resolves dark', () async {
      final SettingsProvider s = SettingsProvider(FakeStorage());
      final ThemeProvider t = ThemeProvider(s);
      expect(t.isDark(true), isTrue);
      expect(t.isDark(false), isFalse);
      await t.choose(ThemeChoice.dark);
      expect(t.value, ThemeChoice.dark);
      expect(t.isDark(false), isTrue);
      await t.choose(ThemeChoice.light);
      expect(t.isDark(true), isFalse);
      t.dispose();
    });

    test('locale resolution', () {
      expect(LocaleProvider.resolve(null, <String>[]), 'en');
      expect(LocaleProvider.resolve(null, <String>['xx', 'pt_BR']), 'pt');
      expect(LocaleProvider.resolve(null, <String>['iw-IL']), 'he');
      expect(LocaleProvider.resolve('ja', <String>['fr']), 'ja');
      expect(LocaleProvider.resolve('xx', <String>['de']), 'de');
      expect(LocaleProvider.resolve('', <String>[]), 'en');
      expect(LocaleProvider.isRtl('ar'), isTrue);
      expect(LocaleProvider.isRtl('en'), isFalse);
    });

    test('locale choice, clearing and device changes', () async {
      final SettingsProvider s = SettingsProvider(FakeStorage());
      final LocaleProvider l = LocaleProvider(s, deviceLanguages: <String>['fr']);
      expect(l.value, 'fr');
      await l.choose('ar');
      expect(l.value, 'ar');
      expect(l.isRightToLeft, isTrue);
      await l.choose(null);
      expect(l.value, 'fr');
      l.deviceLanguagesChanged(<String>['ko']);
      expect(l.value, 'ko');
      l.dispose();
    });
  });

  group('progress and loadout', () {
    test('fresh load is ready with no notice', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      expect(p.value.status, ProgressStatus.loading);
      await p.load();
      expect(p.value.status, ProgressStatus.ready);
      expect(p.value.notice, ProgressNotice.none);
    });

    test('damaged saves start clean with a notice that can be dismissed', () async {
      final FakeStorage storage = FakeStorage()
        ..files['progress.json'] = 'garbage'
        ..files['progress.bak'] = 'garbage';
      final ProgressProvider p = newProgress(storage);
      await p.load();
      expect(p.value.notice, ProgressNotice.startedClean);
      p.dismissNotice();
      expect(p.value.notice, ProgressNotice.none);
    });

    test('a bad main file recovers from the backup', () async {
      final FakeStorage storage = FakeStorage();
      final ProgressProvider first = newProgress(storage);
      await first.load();
      await first.recordAchievements(<String>['first_win']);
      await first.recordAchievements(<String>['no_downs']);
      storage.files['progress.json'] = 'garbage';
      final ProgressProvider second = newProgress(storage);
      await second.load();
      expect(second.value.notice, ProgressNotice.recoveredFromBackup);
    });

    test('a win is recorded, saved, and awards its card once', () async {
      final FakeStorage storage = FakeStorage();
      final ProgressProvider p = newProgress(storage);
      await p.load();
      final String id = StruggleCatalog.career.first.id;
      final FightConfig cfg = FightConfig(
        mode: FightMode.journey,
        struggleId: id,
        cardIds: const <String>[],
        stance: Stance.steady,
        seed: 1,
      );
      final FightResultApplied r = await p.applyFightResult(cfg, won(), <ExchangeRecord>[]);
      expect(r.saved, isTrue);
      expect(r.newCardId, isNotNull);
      expect(p.progress.bouts[id]!.wins, 1);
      final FightResultApplied again = await p.applyFightResult(cfg, won(), <ExchangeRecord>[]);
      expect(again.newCardId, isNull);
      final ProgressProvider reloaded = newProgress(storage);
      await reloaded.load();
      expect(reloaded.progress.bouts[id]!.wins, 2);
    });

    test('an unfinished bout changes nothing', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final FightConfig cfg = FightConfig(
        mode: FightMode.journey,
        struggleId: StruggleCatalog.career.first.id,
        cardIds: const <String>[],
        stance: Stance.steady,
        seed: 1,
      );
      const FightState running = FightState(
        round: 1,
        startingWeight: 100,
        weight: 50,
        player: PlayerState(resolve: 80, stamina: 50, downs: 0, breathCharges: 0),
        exchangeIndex: 3,
        phase: FightPhase.telegraph,
      );
      final FightResultApplied r = await p.applyFightResult(cfg, running, <ExchangeRecord>[]);
      expect(r.saved, isTrue);
      expect(identical(r.before, r.after), isTrue);
    });

    test('achievements are not repeated', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      await p.recordAchievements(<String>['first_win', 'first_win']);
      await p.recordAchievements(<String>['first_win']);
      expect(p.progress.achievements, <String>['first_win']);
    });

    test('a failed save is flagged and retrySave recovers', () async {
      final FakeStorage storage = FakeStorage();
      final ProgressProvider p = newProgress(storage);
      await p.load();
      storage.failWrites = true;
      expect(await p.recordAchievements(<String>['first_win']), isFalse);
      expect(p.value.saveFailed, isTrue);
      storage.failWrites = false;
      expect(await p.retrySave(), isTrue);
      expect(p.value.saveFailed, isFalse);
    });

    test('loadout keeps only earned cards, at most three, no repeats', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final List<String> starters = CardCatalog.starterIds;
      final String locked = CardCatalog.earned.first.id;
      await p.setLoadout(Loadout(
        cardIds: <String>[...starters, starters.first, locked, 'nope'],
        stance: Stance.steady,
      ));
      expect(p.progress.loadout.cardIds.length, lessThanOrEqualTo(3));
      expect(p.progress.loadout.cardIds.contains(locked), isFalse);
      expect(p.progress.loadout.cardIds.toSet().length, p.progress.loadout.cardIds.length);
      expect(await p.setLoadout(p.progress.loadout), isTrue);
    });

    test('loadout provider equips, toggles, sets stance and follows progress', () async {
      final ProgressProvider p = newProgress(FakeStorage());
      await p.load();
      final LoadoutProvider l = LoadoutProvider(p);
      final String first = CardCatalog.starterIds.first;
      expect(l.value.earned.map((c) => c.id), containsAll(CardCatalog.starterIds));
      await l.equip(first);
      expect(l.value.isEquipped(first), isTrue);
      await l.toggle(first);
      expect(l.value.isEquipped(first), isFalse);
      await l.toggle(first);
      expect(l.value.isEquipped(first), isTrue);
      expect(l.value.hasRoom, isTrue);
      await l.setStance(Stance.values.last);
      expect(l.value.loadout.stance, Stance.values.last);
      expect(l.value, l.value);
      expect(l.value.hashCode, l.value.hashCode);
      l.dispose();
    });
  });

  group('entitlement', () {
    test('start reads store state and price', () async {
      final FakeBilling b = FakeBilling();
      final EntitlementProvider e = EntitlementProvider(b);
      expect(e.adsRemoved, isFalse);
      await e.start();
      expect(e.value.storeAvailable, isTrue);
      expect(e.value.priceText, isNotNull);
      expect(e.value.entitlement, Entitlement.none);
      b.emit(Entitlement.adsRemoved);
      await Future<void>.delayed(Duration.zero);
      expect(e.adsRemoved, isTrue);
      e.dispose();
    });

    test('store unavailable has no price', () async {
      final FakeBilling b = FakeBilling()..available = false;
      final EntitlementProvider e = EntitlementProvider(b);
      await e.start();
      expect(e.value.storeAvailable, isFalse);
      expect(e.value.priceText, isNull);
      e.dispose();
    });

    test('buy and restore report the outcome and return to idle', () async {
      final FakeBilling b = FakeBilling();
      final EntitlementProvider e = EntitlementProvider(b);
      await e.start();
      b.nextBuy = PurchaseOutcome.cancelled;
      expect(await e.buy(), PurchaseOutcome.cancelled);
      expect(e.value.activity, EntitlementActivity.idle);
      expect(e.value.lastOutcome, PurchaseOutcome.cancelled);
      await e.restore();
      expect(e.value.activity, EntitlementActivity.idle);
      expect(e.value, e.value);
      expect(e.value.hashCode, e.value.hashCode);
      e.dispose();
    });

    test('a second action while one runs is ignored', () async {
      final FakeBilling b = FakeBilling();
      final EntitlementProvider e = EntitlementProvider(b);
      await e.start();
      final Future<PurchaseOutcome> first = e.buy();
      expect(await e.restore(), PurchaseOutcome.pending);
      await first;
      e.dispose();
    });
  });
}
