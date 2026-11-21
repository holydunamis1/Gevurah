enum HapticKind { tellPulse, hit, perfect, error, selection }

abstract class HapticsPort {
  /// Plays one pulse. Does nothing when the device has no vibration.
  Future<void> play(HapticKind kind);
}
