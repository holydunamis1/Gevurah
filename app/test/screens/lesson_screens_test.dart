import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/training_lessons.dart';
import 'package:gevurah/screens/how_to_play_screen.dart';
import 'package:gevurah/screens/training_screen.dart';

import 'screens_test.dart' show host, makeApp;

void main() {
  testWidgets('How to play shows four cards and Got it', (WidgetTester t) async {
    final r = await makeApp();
    int back = 0;
    await t.pumpWidget(host(r.app, HowToPlayScreen(onBack: () => back++)));
    await t.pump();
    expect(find.byType(HowToPlayScreen), findsOneWidget);
    await t.tap(find.text('Got it'));
    expect(back, 1);
  });

  testWidgets('Training lists six lessons and calls back', (WidgetTester t) async {
    final r = await makeApp();
    final List<String> log = <String>[];
    await t.pumpWidget(host(
      r.app,
      TrainingScreen(
        onLesson: (TrainingLesson l) => log.add(l.id),
        onPractice: () => log.add('practice'),
        onHowToPlay: () => log.add('howto'),
        onBack: () => log.add('back'),
      ),
    ));
    await t.pump();
    expect(find.byType(TrainingScreen), findsOneWidget);
    await t.tap(find.text('How to play'));
    expect(log, <String>['howto']);
  });
}
