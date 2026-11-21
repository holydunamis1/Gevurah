import 'dart:math' as math;

import '../models/beat_offset.dart';
import '../models/exchange_outcome.dart';
import '../models/exchange_record.dart';
import '../models/fight_config.dart';
import '../models/fight_state.dart';
import '../models/move_def.dart';
import '../models/struggle_def.dart';
import 'exchange_resolver.dart';
import 'fight_rules.dart';
import 'modifiers.dart';
import 'progression_rules.dart';
import 'seeded_rng.dart';
import 'stamina.dart';
import 'struggle_ai.dart';
import 'struggle_tuning.dart';

/// How a simulated player behaves.
class BotProfile {
  const BotProfile({
    required this.name,
    required this.sigmaMs,
    required this.choice,
    required this.reading,
  });

  /// A newer player: loose timing, often chooses or reads wrongly.
  static const BotProfile novice = BotProfile(name: 'novice', sigmaMs: 120, choice: 0.5, reading: 0.4);

  /// A regular player.
  static const BotProfile average = BotProfile(name: 'average', sigmaMs: 85, choice: 0.8, reading: 0.7);

  /// A practised player.
  static const BotProfile expert = BotProfile(name: 'expert', sigmaMs: 65, choice: 0.92, reading: 0.85);

  static const List<BotProfile> all = <BotProfile>[novice, average, expert];

  final String name;

  /// Spread of the player's timing error around the beat, in ms (a normal
  /// distribution). The timing windows then decide perfect, good or miss, so
  /// stances and cards that move the windows matter in the simulation.
  final double sigmaMs;

  /// Chance the best response (Slip for heavy, Guard otherwise) is chosen.
  final double choice;

  /// Chance a fake or a bait is recognised.
  final double reading;
}

/// A finished simulated bout.
class BoutResult {
  const BoutResult(this.state, this.history);

  final FightState state;
  final List<ExchangeRecord> history;

  bool get won => ProgressionRules.isWin(state.end);
}

/// Plays a whole bout with no screen: the struggle AI against a seeded bot,
/// through the same resolver and fight rules the game uses. Used by the
/// balance simulation; the same seed always gives the same bout.
abstract final class BoutSimulator {
  /// Telegraph length at which the profile's chances apply, in ms.
  static const double referenceTelegraphMs = 700;

  static const int maxExchanges = 600;

  static BoutResult run(FightConfig config, StruggleDef def, BotProfile bot) {
    final SeededRng root = SeededRng(config.seed);
    final SeededRng aiRng = root.fork('ai');
    final SeededRng botRng = root.fork('bot');
    final Modifiers modifiers = Modifiers.from(cardIds: config.cardIds, stance: config.stance);
    final bool costly = def.hasTrait(StruggleTrait.costly);

    FightState state = FightState.initial(def.weight);
    final List<ExchangeRecord> history = <ExchangeRecord>[];

    while (!state.isFinished && history.length < maxExchanges) {
      if (state.phase == FightPhase.tenCount) {
        state = FightRules.rise(state, _goodTaps(botRng, bot));
        continue;
      }
      if (state.phase == FightPhase.corner) {
        state = FightRules.endCorner(state, def);
        continue;
      }
      if (state.player.stamina < 20 && state.player.breathCharges > 0) {
        state = FightRules.breathe(state);
      }

      final MoveDef move = StruggleAi.nextMove(def, history, aiRng);
      final double telegraph = modifiers.telegraphFor(move).toDouble();
      final double factor = math.sqrt((telegraph / referenceTelegraphMs).clamp(0.25, 1.5));

      final Response response = _chooseResponse(move, botRng, bot);
      final BeatOffset offset = _offset(botRng, bot, factor);
      final OpeningAction counter = _chooseCounter(state, modifiers, response, move, botRng, bot);
      final BeatOffset strikeOffset = _offset(botRng, bot, 0.9);

      final ExchangeOutcome outcome = ExchangeResolver.resolve(
        move: move,
        response: response,
        offset: offset,
        counter: counter,
        strikeOffset: strikeOffset,
        context: ExchangeContext(
          modifiers: modifiers,
          player: state.player,
          assist: config.timingAssist,
          costly: costly,
          incomingDamagePercent: StruggleTuning.incomingDamagePercent(def),
          struggleDamageTakenPercent: StruggleAi.damageTakenPercent(def, history),
        ),
      );
      final ExchangeRecord record = ExchangeRecord(
        index: state.exchangeIndex,
        round: state.round,
        move: move,
        response: response,
        offset: offset,
        outcome: outcome,
        counter: counter,
        strikeOffset: strikeOffset,
      );
      history.add(record);
      state = FightRules.apply(state, record, def);
    }
    if (!state.isFinished) {
      // A bout that never ends is a rules bug; decide it on points.
      state = state.copyWith(
        phase: FightPhase.finished,
        end: FightRules.decision(state.startingWeight, state.weight, state.player),
      );
    }
    return BoutResult(state, history);
  }

  static Response _chooseResponse(MoveDef move, SeededRng rng, BotProfile bot) {
    if (move.kind == MoveKind.fake) {
      return rng.chance(bot.reading) ? Response.takeIt : Response.guard;
    }
    final Response best = move.kind == MoveKind.heavy ? Response.slip : Response.guard;
    if (rng.chance(bot.choice)) {
      return best;
    }
    return best == Response.slip ? Response.guard : Response.slip;
  }

  static OpeningAction _chooseCounter(
    FightState state,
    Modifiers m,
    Response response,
    MoveDef move,
    SeededRng rng,
    BotProfile bot,
  ) {
    if (move.kind == MoveKind.bait && rng.chance(bot.reading)) {
      return OpeningAction.none;
    }
    final int stamina = state.player.stamina;
    if (stamina >= 40 + m.comboStaminaDelta) {
      return OpeningAction.combo;
    }
    if (stamina >= StaminaRules.strikeCost + 2) {
      return OpeningAction.strike;
    }
    return OpeningAction.none;
  }

  /// A timing error drawn from a normal distribution. A longer telegraph
  /// (factor above 1) tightens it; a shorter one loosens it.
  static BeatOffset _offset(SeededRng rng, BotProfile bot, double factor) {
    final double u1 = 1 - rng.nextDouble();
    final double u2 = rng.nextDouble();
    final double z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return BeatOffset(z * bot.sigmaMs / factor);
  }

  static int _goodTaps(SeededRng rng, BotProfile bot) {
    int taps = 0;
    for (int i = 0; i < 5; i++) {
      if (_offset(rng, bot, 1).abs <= TimingWindows.goodMs) {
        taps++;
      }
    }
    return taps;
  }
}
