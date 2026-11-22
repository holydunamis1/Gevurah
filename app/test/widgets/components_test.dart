import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/theme/app_theme.dart';
import 'package:gevurah/theme/icon_aliases.dart';
import 'package:gevurah/theme/tokens.dart';
import 'package:gevurah/widgets/app_card.dart';
import 'package:gevurah/widgets/app_chip.dart';
import 'package:gevurah/widgets/app_row.dart';
import 'package:gevurah/widgets/empty_state.dart';
import 'package:gevurah/widgets/icon_chip.dart';
import 'package:gevurah/widgets/nav_bar.dart';
import 'package:gevurah/widgets/pressable.dart';
import 'package:gevurah/widgets/primary_button.dart';
import 'package:gevurah/widgets/screen_frame.dart';
import 'package:gevurah/widgets/section_header.dart';

Widget wrap(
  Widget child, {
  TextDirection dir = TextDirection.ltr,
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) {
  return MediaQuery(
    data: MediaQueryData(size: const Size(360, 720), textScaler: TextScaler.linear(scale), disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: dir,
      child: AppTheme.forBrightness(brightness: brightness, child: Align(alignment: Alignment.topCenter, child: child)),
    ),
  );
}

double opacityOf(WidgetTester t) => t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity;

void main() {
  group('Pressable', () {
    testWidgets('taps, dims while pressed and recovers', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(wrap(Pressable(onPressed: () => taps++, child: const SizedBox(width: 10, height: 10))));
      expect(opacityOf(t), 1);
      final TestGesture g = await t.startGesture(t.getCenter(find.byType(Pressable)));
      await t.pump();
      expect(opacityOf(t), 0.7);
      await g.up();
      await t.pump();
      expect(opacityOf(t), 1);
      expect(taps, 1);
    });

    testWidgets('a cancelled press recovers without a tap', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(wrap(Pressable(onPressed: () => taps++, child: const SizedBox(width: 10, height: 10))));
      final TestGesture g = await t.startGesture(t.getCenter(find.byType(Pressable)));
      await t.pump();
      await g.moveTo(const Offset(300, 600));
      await g.cancel();
      await t.pump();
      expect(opacityOf(t), 1);
      expect(taps, 0);
    });

    testWidgets('disabled is dimmed and not tappable', (WidgetTester t) async {
      await t.pumpWidget(wrap(const Pressable(onPressed: null, child: SizedBox(width: 10, height: 10))));
      expect(opacityOf(t), 0.4);
      await t.tap(find.byType(Pressable));
      await t.pump();
      expect(opacityOf(t), 0.4);
    });

    testWidgets('the hit area is at least 48 by 48', (WidgetTester t) async {
      await t.pumpWidget(wrap(Pressable(onPressed: () {}, child: const SizedBox(width: 10, height: 10))));
      final Size s = t.getSize(find.byType(Pressable));
      expect(s.width, greaterThanOrEqualTo(48));
      expect(s.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Reduce Motion makes the change instant', (WidgetTester t) async {
      await t.pumpWidget(wrap(Pressable(onPressed: () {}, child: const SizedBox(width: 10, height: 10)), reduceMotion: true));
      expect(t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration, Duration.zero);
    });

    testWidgets('exposes a button with its label', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(wrap(Pressable(onPressed: () {}, semanticLabel: 'Open', child: const SizedBox(width: 10, height: 10))));
      expect(find.bySemanticsLabel('Open'), findsOneWidget);
      h.dispose();
    });
  });

  group('AppCard', () {
    testWidgets('shows icon, label, value and a chevron that flips in RTL', (WidgetTester t) async {
      Widget card() => AppCard(leadingIcon: AppIcons.journey, label: 'Journey', value: '3 of 16', showChevron: true, onPressed: () {});
      await t.pumpWidget(wrap(card()));
      expect(find.text('Journey'), findsOneWidget);
      expect(find.text('3 of 16'), findsOneWidget);
      expect(find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.forward), findsOneWidget);
      await t.pumpWidget(wrap(card(), dir: TextDirection.rtl));
      expect(find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.back), findsOneWidget);
    });

    testWidgets('uses the surface, hairline and radius tokens', (WidgetTester t) async {
      await t.pumpWidget(wrap(const AppCard(label: 'x')));
      final DecoratedBox box = t.widget<DecoratedBox>(find.descendant(of: find.byType(AppCard), matching: find.byType(DecoratedBox)).first);
      final BoxDecoration d = box.decoration as BoxDecoration;
      expect(d.color, AppPalette.light.bgSecondary);
      expect(d.borderRadius, BorderRadius.circular(Radii.card));
      expect((d.border! as Border).top.width, Strokes.hairline);
    });

    testWidgets('a custom child replaces the label row and a plain card is not pressable', (WidgetTester t) async {
      await t.pumpWidget(wrap(const AppCard(child: Text('custom'))));
      expect(find.text('custom'), findsOneWidget);
      expect(find.byType(Pressable), findsNothing);
    });

    testWidgets('tapping a card calls back', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(wrap(AppCard(label: 'x', onPressed: () => taps++)));
      await t.tap(find.text('x'));
      expect(taps, 1);
    });
  });

  group('AppRow', () {
    testWidgets('is at least 48 high, tints on press and taps', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(wrap(AppRow(label: 'Language', leadingIcon: AppIcons.language, value: 'English', onPressed: () => taps++)));
      expect(t.getSize(find.byType(AppRow)).height, greaterThanOrEqualTo(48));
      Color? fill() => (t.widget<DecoratedBox>(find.descendant(of: find.byType(AppRow), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration).color;
      expect(fill(), const Color(0x00000000));
      final TestGesture g = await t.startGesture(t.getCenter(find.byType(AppRow)));
      await t.pump();
      expect(fill(), AppPalette.light.bgTertiary);
      await g.up();
      await t.pump();
      expect(taps, 1);
      expect(fill(), const Color(0x00000000));
    });

    testWidgets('without a handler it has no chevron', (WidgetTester t) async {
      await t.pumpWidget(wrap(const AppRow(label: 'Version')));
      expect(find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.forward), findsNothing);
    });

    testWidgets('chevron mirrors in RTL', (WidgetTester t) async {
      await t.pumpWidget(wrap(AppRow(label: 'x', onPressed: () {}), dir: TextDirection.rtl));
      expect(find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.back), findsOneWidget);
    });
  });

  group('AppChip, SectionHeader, EmptyState', () {
    testWidgets('chip shows its label and icon', (WidgetTester t) async {
      await t.pumpWidget(wrap(const AppChip(label: 'Tier 1', icon: AppIcons.star)));
      expect(find.text('Tier 1'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('section header is uppercase and a semantic header', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(wrap(const SectionHeader('Modes')));
      expect(find.text('MODES'), findsOneWidget);
      expect(t.getSemantics(find.text('MODES')).flagsCollection.isHeader, isTrue);
      h.dispose();
    });

    testWidgets('empty state shows icon, title and subtitle', (WidgetTester t) async {
      await t.pumpWidget(wrap(const EmptyState(icon: AppIcons.library, title: 'Nothing yet', subtitle: 'Win a bout')));
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Win a bout'), findsOneWidget);
      await t.pumpWidget(wrap(const EmptyState(icon: AppIcons.library, title: 'Only title')));
      expect(find.text('Only title'), findsOneWidget);
    });
  });

  group('PrimaryButton', () {
    testWidgets('is accent filled, at least 48 high and taps', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(wrap(PrimaryButton(label: 'Start', icon: AppIcons.play, onPressed: () => taps++)));
      expect(t.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(48));
      final BoxDecoration d = t.widget<DecoratedBox>(find.descendant(of: find.byType(PrimaryButton), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
      expect(d.color, AppPalette.light.accent);
      expect(d.borderRadius, BorderRadius.circular(Radii.button));
      await t.tap(find.text('Start'));
      expect(taps, 1);
    });

    testWidgets('disabled is 40 percent and does nothing', (WidgetTester t) async {
      await t.pumpWidget(wrap(const PrimaryButton(label: 'Start', onPressed: null)));
      expect(opacityOf(t), 0.4);
    });

    testWidgets('uses the dark accent and label colour in dark', (WidgetTester t) async {
      await t.pumpWidget(wrap(PrimaryButton(label: 'Go', onPressed: () {}), brightness: Brightness.dark));
      final BoxDecoration d = t.widget<DecoratedBox>(find.descendant(of: find.byType(PrimaryButton), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
      expect(d.color, AppPalette.dark.accent);
      expect(t.widget<Text>(find.text('Go')).style!.color, AppPalette.dark.onAccent);
    });

    testWidgets('fit-to-label does not fill the width', (WidgetTester t) async {
      await t.pumpWidget(wrap(PrimaryButton(label: 'Go', expand: false, onPressed: () {})));
      expect(t.getSize(find.byType(PrimaryButton)).width, lessThan(200));
    });
  });

  group('IconChip and NavBar', () {
    testWidgets('chip is 40 inside a 48 target and has a label', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      int taps = 0;
      await t.pumpWidget(wrap(IconChip(icon: AppIcons.settings, semanticLabel: 'Settings', onPressed: () => taps++)));
      expect(t.getSize(find.byType(IconChip)), const Size(48, 48));
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      await t.tap(find.byType(IconChip));
      expect(taps, 1);
      h.dispose();
    });

    testWidgets('nav bar shows back, title and actions', (WidgetTester t) async {
      int backs = 0;
      await t.pumpWidget(wrap(SizedBox(
        width: 360,
        child: NavBar(
          title: 'Settings',
          onBack: () => backs++,
          backLabel: 'Back',
          actions: <Widget>[IconChip(icon: AppIcons.help, semanticLabel: 'Help', onPressed: () {})],
        ),
      )));
      expect(find.text('Settings'), findsOneWidget);
      expect(t.getSize(find.byType(NavBar)).height, greaterThanOrEqualTo(NavBar.height));
      await t.tap(find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.back));
      expect(backs, 1);
    });

    testWidgets('nav bar mirrors in RTL: back at the right with a forward arrow', (WidgetTester t) async {
      await t.pumpWidget(wrap(
        SizedBox(width: 360, child: NavBar(title: 'T', onBack: () {}, backLabel: 'Back', actions: <Widget>[IconChip(icon: AppIcons.help, semanticLabel: 'Help', onPressed: () {})])),
        dir: TextDirection.rtl,
      ));
      final Finder arrow = find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.forward);
      expect(arrow, findsOneWidget);
      final double mid = t.getCenter(find.byType(NavBar)).dx;
      expect(t.getCenter(arrow).dx, greaterThan(mid));
      expect(t.getCenter(find.byWidgetPredicate((Widget w) => w is Icon && w.icon == AppIcons.help)).dx, lessThan(mid));
    });

    testWidgets('nav bar shows a brand when there is no back', (WidgetTester t) async {
      await t.pumpWidget(wrap(const SizedBox(width: 360, child: NavBar(title: 'Gevurah', brand: Text('mark')))));
      expect(find.text('mark'), findsOneWidget);
    });
  });

  group('ScreenFrame', () {
    testWidgets('stacks nav bar, content and ad slot, and a missing slot takes no space', (WidgetTester t) async {
      await t.pumpWidget(wrap(
        const SizedBox(
          width: 360,
          height: 640,
          child: ScreenFrame(navBar: Text('nav'), adSlot: SizedBox(height: 50, child: Text('ad')), child: Text('body')),
        ),
      ));
      expect(t.getTopLeft(find.text('nav')).dy, lessThan(t.getTopLeft(find.text('body')).dy));
      expect(t.getTopLeft(find.text('body')).dy, lessThan(t.getTopLeft(find.text('ad')).dy));
      await t.pumpWidget(wrap(
        const SizedBox(width: 360, height: 640, child: ScreenFrame(navBar: Text('nav'), child: Text('body'))),
      ));
      expect(find.text('ad'), findsNothing);
    });
  });

  group('large text', () {
    testWidgets('every component survives 3.1x text with long labels', (WidgetTester t) async {
      const String long = 'A rather long label that must wrap instead of overflowing';
      await t.pumpWidget(wrap(
        SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              children: <Widget>[
                const NavBar(title: long),
                AppCard(leadingIcon: AppIcons.journey, label: long, value: long, showChevron: true, onPressed: () {}),
                AppRow(label: long, leadingIcon: AppIcons.language, value: long, onPressed: () {}),
                const AppChip(label: long, icon: AppIcons.star),
                PrimaryButton(label: long, icon: AppIcons.play, onPressed: () {}),
                const SectionHeader(long),
                const EmptyState(icon: AppIcons.library, title: long, subtitle: long),
              ],
            ),
          ),
        ),
        scale: 3.1,
      ));
      expect(t.takeException(), isNull);
    });
  });
}
