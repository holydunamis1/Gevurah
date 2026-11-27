import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/widgets/app_header.dart';

import '../screens/screens_test.dart' show makeApp;
import 'gevurah_app_test.dart' show pumpApp;

void main() {
  testWidgets('DEBUG header', (WidgetTester t) async {
    final SemanticsHandle h = t.ensureSemantics();
    final r = await makeApp();
    await pumpApp(t, r);
    final String dump = 'HEADER_FOUND=${find.byType(AppHeader).evaluate().length} SEM=${t.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode?.toStringDeep()}';
    h.dispose();
    fail(dump);
  });
}
