import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// One choice in a [SegmentedControl].
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Two to four exclusive choices side by side. The chosen one is filled and
/// bold and is announced as selected.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({super.key, required this.options, required this.selected, required this.onChanged});

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(options.length >= 2 && options.length <= 4, 'A segmented control has two to four choices');
    final AppTheme theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.palette.bgTertiary, borderRadius: BorderRadius.circular(Radii.chip)),
      child: Padding(
        padding: const EdgeInsets.all(Sp.xxs),
        child: Row(
          children: <Widget>[
            for (final SegmentOption<T> o in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: o.value == selected,
                  label: o.label,
                  excludeSemantics: true,
                  onTap: () => onChanged(o.value),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(o.value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: IconSizes.target - 2 * Sp.xxs),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: o.value == selected ? theme.palette.accent : const Color(0x00000000),
                          borderRadius: BorderRadius.circular(Radii.chip - Sp.xxs),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Sp.xs, vertical: Sp.xs),
                            child: Text(
                              o.label,
                              textAlign: TextAlign.center,
                              style: theme.text.callout.copyWith(
                                color: o.value == selected ? theme.palette.onAccent : theme.palette.textPrimary,
                                fontWeight: o.value == selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
