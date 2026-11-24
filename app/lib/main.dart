import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'screens/fight_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(FightScreen.menuOrientations);
  runApp(const BootstrapApp());
}
