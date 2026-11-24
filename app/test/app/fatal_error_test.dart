import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/app/fatal_error.dart';
import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/utils/global_error_handler.dart';

import '../fakes/fakes.dart';

void main() {
  late FatalErrorHost host;
  late FakeLog log;
  late ErrorSink sink;

  setUp(() {
    host = FatalErrorHost();
    log = FakeLog();
    sink = fatalErrorSink(host, log);
  });

  test('an unexpected uncaught error raises the fallback and is logged', () {
    sink(StateError('boom'), StackTrace.current, fatal: true);
    expect(host.value, isTrue);
    expect(log.lines.single, startsWith('error:'));
  });

  test('a framework error is logged but does not raise the fallback', () {
    sink(StateError('layout'), StackTrace.current, fatal: false);
    expect(host.value, isFalse);
    expect(log.lines.single, startsWith('warning:'));
  });

  test('errors the app handles on purpose never raise the fallback', () {
    for (final AppError e in const <AppError>[UserRecoverableError('no'), ThirdPartyError('ad'), StorageError('disk')]) {
      sink(e, null, fatal: true);
    }
    expect(host.value, isFalse);
    expect(log.lines, hasLength(3));
  });

  test('a fatal AppError raises it', () {
    sink(const FatalError('x'), null, fatal: true);
    expect(host.value, isTrue);
  });

  test('clear lowers it', () {
    host.raise();
    host.clear();
    expect(host.value, isFalse);
  });
}
