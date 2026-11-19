import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib/core must stay pure Dart: no Flutter, no plugins, no dart:io or dart:ui,
/// and nothing from the outer layers.
void main() {
  test('lib/core imports nothing from outer layers or plugins', () {
    final Directory core = Directory('lib/core');
    if (!core.existsSync()) {
      return; // Nothing to check until the core layer exists.
    }
    final RegExp directive = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"]''');
    final List<String> forbidden = <String>[
      'dart:io',
      'dart:ui',
      'package:flutter/',
      'package:flame',
      'package:google_mobile_ads',
      'package:in_app_purchase',
      'package:shared_preferences',
      'package:path_provider',
      'package:flutter_local_notifications',
      'package:flutter_timezone',
      'package:connectivity_plus',
      'package:url_launcher',
      'package:gevurah/platform/',
      'package:gevurah/providers/',
      'package:gevurah/game/',
      'package:gevurah/screens/',
      'package:gevurah/widgets/',
      'package:gevurah/theme/',
    ];
    final List<String> violations = <String>[];
    for (final FileSystemEntity entity in core.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final RegExpMatch? match = directive.firstMatch(lines[i]);
        if (match == null) {
          continue;
        }
        final String target = match.group(2)!;
        for (final String bad in forbidden) {
          if (target.startsWith(bad)) {
            violations.add('${entity.path}:${i + 1} imports $target');
          }
        }
        if (target.startsWith('../') && (target.contains('platform/') || target.contains('screens/') || target.contains('widgets/') || target.contains('providers/') || target.contains('game/') || target.contains('theme/'))) {
          violations.add('${entity.path}:${i + 1} imports $target');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
