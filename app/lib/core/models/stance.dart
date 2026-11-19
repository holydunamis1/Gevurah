/// A stance chosen in the corner between rounds. Each trades one strength
/// for one weakness. The modifiers are tuning starting values.
enum Stance {
  /// Wider guard windows, smaller strike damage.
  steady(guardWindowDeltaMs: 15, strikeDamagePercent: -15, telegraphDeltaMs: 0, staminaRegenPercent: 0),

  /// Larger strike damage, narrower guard windows.
  bold(guardWindowDeltaMs: -15, strikeDamagePercent: 20, telegraphDeltaMs: 0, staminaRegenPercent: 0),

  /// Longer telegraphs seen, slower Stamina recovery.
  patient(guardWindowDeltaMs: 0, strikeDamagePercent: 0, telegraphDeltaMs: 120, staminaRegenPercent: -25);

  const Stance({
    required this.guardWindowDeltaMs,
    required this.strikeDamagePercent,
    required this.telegraphDeltaMs,
    required this.staminaRegenPercent,
  });

  /// Milliseconds added to (or removed from) guard windows.
  final int guardWindowDeltaMs;

  /// Percent change to strike damage.
  final int strikeDamagePercent;

  /// Milliseconds added to the visible telegraph.
  final int telegraphDeltaMs;

  /// Percent change to Stamina regeneration.
  final int staminaRegenPercent;
}
