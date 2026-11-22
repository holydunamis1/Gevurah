import 'package:flutter/widgets.dart';

import '../core/models/verse_card_def.dart';
import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// One equippable verse card: its name and reference, what it changes and what
/// it costs. Equipped and locked are shown by an icon and a label as well as a
/// border, so colour is never the only signal.
class CardSlot extends StatelessWidget {
  const CardSlot({
    super.key,
    required this.type,
    required this.title,
    required this.reference,
    required this.effect,
    required this.tradeoff,
    this.equipped = false,
    this.locked = false,
    this.stateLabel,
    this.onPressed,
  }) : assert(!(equipped || locked) || stateLabel != null, 'An equipped or locked card needs its state label');

  final CardType type;
  final String title;
  final String reference;
  final String effect;
  final String tradeoff;
  final bool equipped;
  final bool locked;

  /// The text for the state, for example "Equipped" or "Locked".
  final String? stateLabel;
  final VoidCallback? onPressed;

  static IconData iconFor(CardType type) {
    switch (type) {
      case CardType.strike:
        return AppIcons.strike;
      case CardType.guard:
        return AppIcons.guard;
      case CardType.insight:
        return AppIcons.timing;
      case CardType.steadiness:
        return AppIcons.resolve;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final Color border = equipped ? theme.palette.accent : theme.palette.hairline;
    final double borderWidth = equipped ? 2 : Strokes.hairline;
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgSecondary,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppIcon(iconFor(type), color: theme.palette.accent),
                const SizedBox(width: Sp.sm),
                Expanded(child: Text(title, style: theme.text.title2)),
                if (equipped || locked) ...<Widget>[
                  const SizedBox(width: Sp.sm),
                  AppIcon(equipped ? AppIcons.check : AppIcons.locked, size: IconSizes.medium, color: theme.palette.textSecondary),
                  const SizedBox(width: Sp.xs),
                  Flexible(child: Text(stateLabel!, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
                ],
              ],
            ),
            const SizedBox(height: Sp.xxs),
            Text(reference, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
            const SizedBox(height: Sp.sm),
            Text(effect, style: theme.text.footnote),
            const SizedBox(height: Sp.xs),
            Text(tradeoff, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary)),
          ],
        ),
      ),
    );
    if (onPressed == null) {
      return card;
    }
    return Pressable(onPressed: onPressed, minHeight: 0, minWidth: 0, child: card);
  }
}
