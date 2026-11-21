import 'package:flutter/services.dart';

import '../core/ports/haptics_port.dart';

/// Haptic pulses through the platform. Failures and devices without a
/// vibration motor do nothing.
class HapticsService implements HapticsPort {
  /// Turned off from Settings.
  bool enabled = true;

  @override
  Future<void> play(HapticKind kind) async {
    if (!enabled) {
      return;
    }
    try {
      switch (kind) {
        case HapticKind.tellPulse:
          await HapticFeedback.lightImpact();
        case HapticKind.hit:
          await HapticFeedback.mediumImpact();
        case HapticKind.perfect:
          await HapticFeedback.heavyImpact();
        case HapticKind.error:
          await HapticFeedback.vibrate();
        case HapticKind.selection:
          await HapticFeedback.selectionClick();
      }
    } on PlatformException {
      // No vibration available: nothing to do.
    }
  }
}
