import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/verse_card_def.dart';
import 'package:gevurah/theme/app_theme.dart';
import 'package:gevurah/theme/icon_aliases.dart';
import 'package:gevurah/theme/tokens.dart';
import 'package:gevurah/widgets/ad_slot.dart';
import 'package:gevurah/widgets/app_dialog.dart';
import 'package:gevurah/widgets/bottom_sheet.dart';
import 'package:gevurah/widgets/card_slot.dart';
import 'package:gevurah/widgets/entitlement_badge.dart';
import 'package:gevurah/widgets/error_state_view.dart';
import 'package:gevurah/widgets/feedback_banner.dart';
import 'package:gevurah/widgets/fight_meter.dart';
import 'package:gevurah/widgets/segmented_control.dart';
import 'package:gevurah/widgets/star_row.dart';
import 'package:gevurah/widgets/stat_pill.dart';
import 'package:gevurah/widgets/tell_overlay.dart';
import 'package:gevurah/widgets/toggle_row.dart';
import 'package:gevurah/widgets/verse_card.dart';
import 'package:gevurah/widgets/warning_banner.dart';

Widget wrap(
  Widget child, {
  TextDirection dir = TextDirection.ltr,
  double scale = 1,
  Brightness brightness = Brightness.light,
  EdgeInsets insets = EdgeInsets.zero,
  bool reduceMotion = false,
}) {
  return MediaQuery(
    data: MediaQueryData(size: const Size(360, 720), textScaler: TextScaler.linear(scale), viewInsets: insets, disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: dir,
      child: AppTheme.forBrightness(brightness: brightness, child: Align(alignment: Alignment.topCenter, child: SizedBox(width: 360, child: child))),
    ),
  );
}

Finder iconOf(IconData d) => find.byWidgetPredicate((Widget w) => w is Icon && w.icon == d);

void main() {
  group('VerseCard', () {
    testWidgets('shows the text exactly and the reference', (WidgetTester t) async {
      const String verse = 'Therefore take up the whole armor of God, that you may be able to stand.';
      await t.pumpWidget(wrap(const VerseCard(text: verse, reference: 'Ephesians 6:13', translation: 'BSB')));
      expect(find.text(verse), findsOneWidget);
      expect(find.text('Ephesians 6:13'), findsOneWidget);
      expect(find.text('BSB'), findsOneWidget);
      final BoxDecoration d = t.widget<DecoratedBox>(find.descendant(of: find.byType(VerseCard), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
      expect(d.color, AppPalette.light.verseCardSurface);
      await t.pumpWidget(wrap(const VerseCard(text: verse, reference: 'x')));
      expect(find.text('BSB'), findsNothing);
    });
  });

  group('FightMeter', () {
    testWidgets('has an icon, a label and a number for each kind', (WidgetTester t) async {
      for (final MeterKind k in MeterKind.values) {
        await t.pumpWidget(wrap(FightMeter(kind: k, value: 40, max: 100, label: 'L', valueText: '40')));
        expect(find.text('L'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(iconOf(FightMeter.iconFor(k)), findsOneWidget);
      }
    });

    testWidgets('the fill follows the value, clamped, and uses the domain colours', (WidgetTester t) async {
      double factor() => t.widget<FractionallySizedBox>(find.byKey(const ValueKey<String>('fill'))).widthFactor!;
      await t.pumpWidget(wrap(const FightMeter(kind: MeterKind.resolve, value: 25, max: 100, label: 'R', valueText: '25')));
      expect(factor(), 0.25);
      await t.pumpWidget(wrap(const FightMeter(kind: MeterKind.stamina, value: 500, max: 100, label: 'S', valueText: '100')));
      expect(factor(), 1);
      await t.pumpWidget(wrap(const FightMeter(kind: MeterKind.weight, value: -5, max: 100, label: 'W', valueText: '0')));
      expect(factor(), 0);
      Color fill() => (t.widget<DecoratedBox>(find.descendant(of: find.byKey(const ValueKey<String>('fill')), matching: find.byType(DecoratedBox))).decoration as BoxDecoration).color!;
      expect(fill(), AppPalette.light.weightFill);
      await t.pumpWidget(wrap(const FightMeter(kind: MeterKind.resolve, value: 1, max: 2, label: 'R', valueText: '1')));
      expect(fill(), AppPalette.light.resolveFill);
      await t.pumpWidget(wrap(const FightMeter(kind: MeterKind.stamina, value: 1, max: 2, label: 'S', valueText: '1')));
      expect(fill(), AppPalette.light.staminaFill);
    });

    testWidgets('the fill starts at the start edge in RTL', (WidgetTester t) async {
      await t.pumpWidget(wrap(const FightMeter(kind: MeterKind.resolve, value: 50, max: 100, label: 'R', valueText: '50'), dir: TextDirection.rtl));
      final Rect fill = t.getRect(find.byKey(const ValueKey<String>('fill')));
      expect(fill.right, greaterThan(180));
    });
  });

  group('TellOverlay', () {
    testWidgets('draws every kind with its label and clamps progress', (WidgetTester t) async {
      for (final MoveKind k in MoveKind.values) {
        await t.pumpWidget(wrap(TellOverlay(kind: k, progress: 1.7, label: k.name)));
        expect(find.text(k.name), findsOneWidget);
        expect(t.takeException(), isNull);
      }
    });

    testWidgets('painter repaints only on change', (WidgetTester t) async {
      const Color c = Color(0xFFFFFFFF);
      const TellPainter a = TellPainter(kind: MoveKind.heavy, progress: 0.5, color: c, track: c);
      expect(a.shouldRepaint(const TellPainter(kind: MoveKind.heavy, progress: 0.5, color: c, track: c)), isFalse);
      expect(a.shouldRepaint(const TellPainter(kind: MoveKind.heavy, progress: 0.6, color: c, track: c)), isTrue);
      expect(a.shouldRepaint(const TellPainter(kind: MoveKind.fake, progress: 0.5, color: c, track: c)), isTrue);
      expect(a.shouldRepaint(const TellPainter(kind: MoveKind.heavy, progress: 0.5, color: Color(0xFF000000), track: c)), isTrue);
      expect(a.shouldRepaint(const TellPainter(kind: MoveKind.heavy, progress: 0.5, color: c, track: Color(0xFF000000))), isTrue);
    });
  });

  group('CardSlot', () {
    Widget slot({bool equipped = false, bool locked = false, VoidCallback? onPressed, CardType type = CardType.strike}) => CardSlot(
          type: type,
          title: 'Steady Hand',
          reference: 'Psalm 18:34',
          effect: 'Perfect strikes deal more damage',
          tradeoff: 'Combos cost 2 more Stamina',
          equipped: equipped,
          locked: locked,
          stateLabel: equipped ? 'Equipped' : (locked ? 'Locked' : null),
          onPressed: onPressed,
        );

    testWidgets('shows name, reference, effect and trade-off', (WidgetTester t) async {
      await t.pumpWidget(wrap(slot()));
      expect(find.text('Steady Hand'), findsOneWidget);
      expect(find.text('Psalm 18:34'), findsOneWidget);
      expect(find.text('Perfect strikes deal more damage'), findsOneWidget);
      expect(find.text('Combos cost 2 more Stamina'), findsOneWidget);
    });

    testWidgets('equipped and locked carry an icon and a label, not only a border', (WidgetTester t) async {
      await t.pumpWidget(wrap(slot(equipped: true)));
      expect(find.text('Equipped'), findsOneWidget);
      expect(iconOf(AppIcons.check), findsOneWidget);
      await t.pumpWidget(wrap(slot(locked: true)));
      expect(find.text('Locked'), findsOneWidget);
      expect(iconOf(AppIcons.locked), findsOneWidget);
    });

    testWidgets('every type has its own icon', (WidgetTester t) async {
      final Set<IconData> icons = CardType.values.map(CardSlot.iconFor).toSet();
      expect(icons.length, CardType.values.length);
    });

    testWidgets('taps only when given a handler', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(wrap(slot(onPressed: () => taps++)));
      await t.tap(find.text('Steady Hand'));
      expect(taps, 1);
      await t.pumpWidget(wrap(slot()));
      expect(find.byType(CardSlot), findsOneWidget);
    });
  });

  group('StarRow, StatPill, EntitlementBadge', () {
    testWidgets('stars: earned are full, others faded, label shown', (WidgetTester t) async {
      await t.pumpWidget(wrap(const StarRow(stars: 2, label: '2 of 3')));
      expect(find.byKey(const ValueKey<String>('star-on-0')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('star-on-1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('star-off-2')), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      await t.pumpWidget(wrap(const StarRow(stars: 0, label: '0 of 3')));
      expect(find.byKey(const ValueKey<String>('star-on-0')), findsNothing);
    });

    testWidgets('stat pill shows label and value', (WidgetTester t) async {
      await t.pumpWidget(wrap(const StatPill(label: 'Downs', value: '0')));
      expect(find.text('Downs'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('badge shows only when ads are removed', (WidgetTester t) async {
      await t.pumpWidget(wrap(const EntitlementBadge(adsRemoved: true, label: 'Ads removed')));
      expect(find.text('Ads removed'), findsOneWidget);
      await t.pumpWidget(wrap(const EntitlementBadge(adsRemoved: false, label: 'Ads removed')));
      expect(find.text('Ads removed'), findsNothing);
    });
  });

  group('AdSlot', () {
    const Widget banner = SizedBox(width: 320, height: 50, child: Text('AD'));

    testWidgets('shows a ready banner with a top hairline', (WidgetTester t) async {
      await t.pumpWidget(wrap(const AdSlot(visible: true, banner: banner)));
      expect(find.text('AD'), findsOneWidget);
      expect(t.getSize(find.byType(AdSlot)).height, 50);
    });

    testWidgets('collapses to nothing in every absent case', (WidgetTester t) async {
      final List<Widget> absent = <Widget>[
        wrap(const AdSlot(visible: false, banner: banner)),
        wrap(const AdSlot(visible: true, banner: null)),
        wrap(const AdSlot(visible: false, banner: null)),
        wrap(const AdSlot(visible: true, banner: banner), insets: const EdgeInsets.only(bottom: 300)),
      ];
      for (final Widget w in absent) {
        await t.pumpWidget(w);
        expect(t.getSize(find.byType(AdSlot)), Size.zero);
        expect(find.text('AD'), findsNothing);
        expect(find.descendant(of: find.byType(AdSlot), matching: find.byType(DecoratedBox)), findsNothing);
      }
    });
  });

  group('ToggleRow and SegmentedControl', () {
    testWidgets('toggle flips through the callback and exposes its state', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      bool value = false;
      await t.pumpWidget(wrap(StatefulBuilder(
        builder: (BuildContext c, StateSetter set) => ToggleRow(label: 'Sound', icon: AppIcons.sound, subtitle: 'Effects', value: value, onChanged: (bool v) => set(() => value = v)),
      )));
      expect(t.getSemantics(find.byType(ToggleRow)).flagsCollection.isToggled, isFalse);
      await t.tap(find.text('Sound'));
      await t.pumpAndSettle();
      expect(value, isTrue);
      expect(t.getSemantics(find.byType(ToggleRow)).flagsCollection.isToggled, isTrue);
      expect(t.getSize(find.byType(ToggleRow)).height, greaterThanOrEqualTo(48));
      h.dispose();
    });

    testWidgets('a disabled toggle does nothing and is dimmed', (WidgetTester t) async {
      await t.pumpWidget(wrap(const ToggleRow(label: 'Sound', value: true, onChanged: null)));
      await t.tap(find.text('Sound'));
      expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 0.4);
    });

    testWidgets('knob sits at the end when on, mirrored in RTL', (WidgetTester t) async {
      await t.pumpWidget(wrap(ToggleRow(label: 'x', value: true, onChanged: (bool _) {}), dir: TextDirection.rtl, reduceMotion: true));
      expect(t.widget<AnimatedContainer>(find.byType(AnimatedContainer)).alignment, AlignmentDirectional.centerEnd);
    });

    testWidgets('segmented control selects, announces and reports', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      String? chosen;
      await t.pumpWidget(wrap(SegmentedControl<String>(
        options: const <SegmentOption<String>>[
          SegmentOption<String>(value: 'a', label: 'System'),
          SegmentOption<String>(value: 'b', label: 'Light'),
          SegmentOption<String>(value: 'c', label: 'Dark'),
        ],
        selected: 'b',
        onChanged: (String v) => chosen = v,
      )));
      expect(t.getSemantics(find.text('Light')).flagsCollection.isSelected.toBoolOrNull(), isTrue);
      await t.tap(find.text('Dark'));
      expect(chosen, 'c');
      h.dispose();
    });
  });

  group('sheet and dialog', () {
    testWidgets('sheet surface has a title, a handle and 20 top radius only', (WidgetTester t) async {
      await t.pumpWidget(wrap(const AppBottomSheet(title: 'Stance', child: Text('body'))));
      expect(find.text('Stance'), findsOneWidget);
      final BoxDecoration d = t.widget<DecoratedBox>(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
      expect(d.borderRadius, const BorderRadius.vertical(top: Radius.circular(Radii.sheet)));
      await t.pumpWidget(wrap(const AppBottomSheet(child: Text('only'))));
      expect(find.text('only'), findsOneWidget);
    });

    testWidgets('showAppBottomSheet opens and closes by tapping outside', (WidgetTester t) async {
      late BuildContext ctx;
      await t.pumpWidget(wrap(Builder(builder: (BuildContext c) {
        ctx = c;
        return const SizedBox();
      })));
      Future<String?> result = Future<String?>.value();
      result = showAppBottomSheet<String>(ctx, barrierLabel: 'Close', builder: (BuildContext c) => const AppBottomSheet(title: 'Sheet', child: Text('inside')));
      await t.pumpAndSettle();
      expect(find.text('inside'), findsOneWidget);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(find.text('inside'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('dialog shows its parts and calls its actions', (WidgetTester t) async {
      int primary = 0;
      int secondary = 0;
      await t.pumpWidget(wrap(AppDialog(
        title: 'Reset?',
        message: 'This clears your progress.',
        primary: AppDialogAction(label: 'Reset', onPressed: () => primary++),
        secondary: AppDialogAction(label: 'Cancel', onPressed: () => secondary++),
      )));
      expect(find.text('Reset?'), findsOneWidget);
      expect(find.text('This clears your progress.'), findsOneWidget);
      await t.tap(find.text('Reset'));
      await t.tap(find.text('Cancel'));
      expect(primary, 1);
      expect(secondary, 1);
      await t.pumpWidget(wrap(AppDialog(title: 'T', message: 'M', primary: AppDialogAction(label: 'OK', onPressed: () {}))));
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('showAppDialog opens over the screen and closes through an action', (WidgetTester t) async {
      late BuildContext ctx;
      await t.pumpWidget(wrap(Builder(builder: (BuildContext c) {
        ctx = c;
        return const SizedBox();
      })));
      final Future<bool?> result = showAppDialog<bool>(
        ctx,
        barrierLabel: 'Close',
        dialog: AppDialog(title: 'T', message: 'M', primary: AppDialogAction(label: 'Yes', onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true))),
      );
      await t.pumpAndSettle();
      expect(find.text('M'), findsOneWidget);
      await t.tap(find.text('Yes'));
      await t.pumpAndSettle();
      expect(await result, isTrue);
    });
  });

  group('banners and error view', () {
    testWidgets('feedback banner shows the right icon for each kind and dismisses', (WidgetTester t) async {
      int dismissed = 0;
      await t.pumpWidget(wrap(FeedbackBanner(kind: FeedbackKind.success, message: 'Saved', onDismiss: () => dismissed++, dismissLabel: 'Dismiss')));
      expect(iconOf(AppIcons.check), findsOneWidget);
      await t.tap(iconOf(AppIcons.close));
      expect(dismissed, 1);
      await t.pumpWidget(wrap(const FeedbackBanner(kind: FeedbackKind.failure, message: 'Not saved')));
      expect(iconOf(AppIcons.error), findsOneWidget);
      expect(iconOf(AppIcons.close), findsNothing);
      await t.pumpWidget(wrap(const FeedbackBanner(kind: FeedbackKind.info, message: 'Note')));
      expect(iconOf(AppIcons.info), findsOneWidget);
    });

    testWidgets('warning banner has a warning icon and an optional action', (WidgetTester t) async {
      int retries = 0;
      await t.pumpWidget(wrap(WarningBanner(message: 'Could not save', actionLabel: 'Retry', onAction: () => retries++)));
      expect(iconOf(AppIcons.warning), findsOneWidget);
      await t.tap(find.text('Retry'));
      expect(retries, 1);
      await t.pumpWidget(wrap(const WarningBanner(message: 'Just a notice')));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('error view offers retry and a report link and shows no trace', (WidgetTester t) async {
      int retries = 0;
      int reports = 0;
      await t.pumpWidget(wrap(
        SizedBox(
          height: 640,
          child: ErrorStateView(title: 'Something went wrong', message: 'Please try again.', retryLabel: 'Try again', onRetry: () => retries++, reportLabel: 'Email a report', onReport: () => reports++),
        ),
      ));
      await t.tap(find.text('Try again'));
      await t.tap(find.text('Email a report'));
      expect(retries, 1);
      expect(reports, 1);
      await t.pumpWidget(wrap(SizedBox(height: 640, child: ErrorStateView(title: 'T', message: 'M', retryLabel: 'Retry', onRetry: () {}))));
      expect(find.text('Email a report'), findsNothing);
    });
  });

  group('large text and dark', () {
    testWidgets('feature widgets survive 3.1x text with long labels', (WidgetTester t) async {
      const String long = 'A rather long label that must wrap instead of overflowing';
      await t.pumpWidget(wrap(
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const VerseCard(text: long, reference: long, translation: long),
              const FightMeter(kind: MeterKind.resolve, value: 50, max: 100, label: long, valueText: '50'),
              const TellOverlay(kind: MoveKind.heavy, progress: 0.5, label: long),
              const CardSlot(type: CardType.guard, title: long, reference: long, effect: long, tradeoff: long, equipped: true, stateLabel: long),
              const StarRow(stars: 3, label: long),
              const StatPill(label: long, value: long),
              ToggleRow(label: long, subtitle: long, icon: AppIcons.sound, value: true, onChanged: (bool _) {}),
              SegmentedControl<int>(
                options: const <SegmentOption<int>>[SegmentOption<int>(value: 1, label: long), SegmentOption<int>(value: 2, label: long)],
                selected: 1,
                onChanged: (int _) {},
              ),
              const FeedbackBanner(kind: FeedbackKind.failure, message: long),
              WarningBanner(message: long, actionLabel: 'Retry', onAction: () {}),
              const EntitlementBadge(adsRemoved: true, label: long),
            ],
          ),
        ),
        scale: 3.1,
      ));
      expect(t.takeException(), isNull);
    });

    testWidgets('dark theme uses the dark tokens', (WidgetTester t) async {
      await t.pumpWidget(wrap(const VerseCard(text: 'x', reference: 'y'), brightness: Brightness.dark));
      final BoxDecoration d = t.widget<DecoratedBox>(find.descendant(of: find.byType(VerseCard), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
      expect(d.color, AppPalette.dark.verseCardSurface);
    });
  });
}
