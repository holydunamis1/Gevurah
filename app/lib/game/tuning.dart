import '../core/models/move_def.dart';

/// The single tuning file for the fight scene: controller timing, animation
/// timings, layout and sound ids. Rules and damage live in core; nothing here
/// changes an outcome except the timing windows' surroundings (how long a
/// response or opening stays open), which are set once, here.
abstract final class GameTuning {
  // Controller timing, in milliseconds.

  /// How long the response stays open after the beat.
  static const double responseCloseMs = 400;

  /// From the response to the opening's beat.
  static const double openingDelayMs = 350;

  /// How long the opening stays open after its beat.
  static const double openingCloseMs = 400;

  /// How long an exchange's result is shown before the next telegraph.
  static const double resolveShowMs = 450;

  /// A short breath between exchanges.
  static const double interExchangeMs = 250;

  /// The one-tap game's rest between exchanges, when the player may punch.
  static const double easyRestMs = 1600;

  /// A free punch's damage and the shortest gap between two of them.
  static const int freePunchDamage = 3;
  static const double freePunchGapMs = 230;

  /// The wait before the first telegraph, and after a corner, ten-count or pause.
  static const double resumeLeadMs = 700;

  // Animation, in milliseconds.
  static const double poseBlendMs = 120;
  static const double poseHoldMs = 320;
  static const double staggerMs = 520;
  static const double lungeMs = 180;
  static const double flinchMs = 260;
  static const double impactMs = 280;
  static const double starsMs = 700;
  static const double defeatLiftMs = 600;
  static const double riseMs = 500;

  /// With Reduce Motion, effects become a flash of this length with no movement.
  static const double reducedFlashMs = 200;

  // Layout, as fractions of the scene size.
  static const double floorY = 0.80;
  static const double playerX = 0.26;
  static const double shadowX = 0.74;
  static const double figureHeight = 0.42;

  // Sound ids, played through the audio port. The files are in assets/audio.
  static const String soundTell = 'tell';
  static const String soundHit = 'hit';
  static const String soundPerfect = 'perfect';
  static const String soundGuard = 'guard';
  static const String soundSlip = 'slip';
  static const String soundDown = 'down';
  static const String soundDefeat = 'defeat';
  static const String soundTellHeavy = 'tell_heavy';
  static const String soundTellFlurry = 'tell_flurry';
  static const String soundCount = 'count';
  static const String soundBell = 'bell';
  static const String soundWin = 'win';
  static const String soundLose = 'lose';
  static const String soundMusic = 'music';
  static const List<String> allSounds = <String>[
    soundTell,
    soundTellHeavy,
    soundTellFlurry,
    soundHit,
    soundPerfect,
    soundGuard,
    soundSlip,
    soundDown,
    soundDefeat,
    soundCount,
    soundBell,
    soundWin,
    soundLose,
    soundMusic,
  ];

  /// The tell's sound by move. A fake and a bait sound like the strike they
  /// imitate, so the ear cannot give them away any more than the eye can.
  static String tellSound(MoveKind kind) => switch (kind) {
        MoveKind.heavy => soundTellHeavy,
        MoveKind.flurry => soundTellFlurry,
        MoveKind.strike || MoveKind.ping || MoveKind.fake || MoveKind.bait || MoveKind.drain => soundTell,
      };
}
