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

/// How a simulated player behaves. All chances are 0 to 1.
class BotProfile {
  const BotProfile({
    required this.name,
    required this.perfect,
    required this.good,
    required this.choice,
    required this.reading,
  });

  /// A newer player: mostly good timing, few perfects, often reads wrongly.
  static const BotProfile novice = BotProfile(name: 'novice', perfect: 0.15, good: 0.45, choice: 0.5, reading: 0.4);

  /// A regular player.
  static const BotProfile average = BotProfile(name: 'average', perfect: 0.35, good: 0.45, choice: 0.8, reading: 0.7);

  /// A practised player.
  static const BotProfile expert = BotProfile(name: 'expert', perfect: 0.65, good: 0.28, choice: 0.97, reading: 0.93);

  static const List<BotProfile> all = <BotProfile>[novice, average, expert];

  final String name;

  /// Chance a response lands perfect at a reference telegraph.
  final double perfect;

  /// Chance a response lands good (not perfect).
  final double good;

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
      final double factor = (telegraph / referenceTelegraphMs).clamp(0.5, 1.2);

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

  static BeatOffset _offset(SeededRng rng, BotProfile bot, double factor) {
    final double perfect = (bot.perfect * factor).clamp(0.0, 1.0);
    final double good = (bot.good * (0.5 + 0.5 * factor)).clamp(0.0, 1.0 - perfect);
    final double r = rng.nextDouble();
    final double sign = rng.chance(0.5) ? 1 : -1;
    final double u = rng.nextDouble();
    if (r < perfect) {
      return BeatOffset(sign * 45 * u);
    }
    if (r < perfect + good) {
      return BeatOffset(sign * (55 + 60 * u));
    }
    return BeatOffset(sign * (130 + 170 * u));
  }

  static int _goodTaps(SeededRng rng, BotProfile bot) {
    int taps = 0;
    for (int i = 0; i < 5; i++) {
      if (rng.chance(bot.perfect + bot.good)) {
        taps++;
      }
    }
    return taps;
  }
}
