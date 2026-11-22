import 'package:flutter/foundation.dart';

import '../core/catalog/card_catalog.dart';
import '../core/models/loadout.dart';
import '../core/models/progress.dart';
import '../core/models/stance.dart';
import '../core/models/verse_card_def.dart';
import 'progress_provider.dart';

class LoadoutState {
  const LoadoutState({required this.loadout, required this.earned});

  final Loadout loadout;

  /// Every card the player has earned, in catalog order.
  final List<VerseCardDef> earned;

  bool isEquipped(String cardId) => loadout.cardIds.contains(cardId);

  /// Whether another card could be equipped.
  bool get hasRoom => !loadout.isFull;

  @override
  bool operator ==(Object other) =>
      other is LoadoutState &&
      other.loadout == loadout &&
      other.earned.length == earned.length &&
      List<bool>.generate(earned.length, (int i) => earned[i].id == other.earned[i].id).every((bool b) => b);

  @override
  int get hashCode => Object.hash(loadout, earned.length);
}

/// The strategy choice: up to three earned cards and a stance, saved with progress.
class LoadoutProvider extends ValueNotifier<LoadoutState> {
  LoadoutProvider(this._progress) : super(_build(_progress.progress)) {
    _progress.addListener(_sync);
  }

  final ProgressProvider _progress;

  static LoadoutState _build(Progress p) => LoadoutState(
        loadout: p.loadout,
        earned: CardCatalog.all.where((VerseCardDef c) => p.cardsEarned.contains(c.id)).toList(growable: false),
      );

  void _sync() => value = _build(_progress.progress);

  Future<bool> equip(String cardId) => _progress.setLoadout(value.loadout.equip(cardId));

  Future<bool> unequip(String cardId) => _progress.setLoadout(value.loadout.unequip(cardId));

  /// Equips the card if it is not equipped and there is room; unequips it otherwise.
  Future<bool> toggle(String cardId) => value.isEquipped(cardId) ? unequip(cardId) : equip(cardId);

  Future<bool> setStance(Stance stance) => _progress.setLoadout(value.loadout.copyWith(stance: stance));

  @override
  void dispose() {
    _progress.removeListener(_sync);
    super.dispose();
  }
}
