import 'package:flutter/widgets.dart';

import '../theme/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/icon_aliases.dart';
import '../theme/tokens.dart';

/// The one list row: transparent, leading icon, label, optional value and a
/// trailing chevron. Pressing tints the background (no dimming).
class AppRow extends StatefulWidget {
  const AppRow({
    super.key,
    required this.label,
    this.leadingIcon,
    this.value,
    this.onPressed,
    this.showChevron = true,
    this.semanticLabel,
  });

  final String label;
  final IconData? leadingIcon;
  final String? value;
  final VoidCallback? onPressed;
  final bool showChevron;
  final String? semanticLabel;

  @override
  State<AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<AppRow> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTheme theme = AppTheme.of(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final bool enabled = widget.onPressed != null;
    final Widget row = DecoratedBox(
      decoration: BoxDecoration(
        color: _pressed ? theme.palette.bgTertiary : const Color(0x00000000),
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: IconSizes.target),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.sm),
          child: Row(
            children: <Widget>[
              if (widget.leadingIcon != null) ...<Widget>[
                AppIcon(widget.leadingIcon!, color: theme.palette.textSecondary),
                const SizedBox(width: Sp.md),
              ],
              Expanded(child: Text(widget.label, style: theme.text.callout)),
              if (widget.value != null) ...<Widget>[
                const SizedBox(width: Sp.sm),
                Flexible(child: Text(widget.value!, style: theme.text.footnote.copyWith(color: theme.palette.textSecondary))),
              ],
              if (widget.showChevron && enabled) ...<Widget>[
                const SizedBox(width: Sp.sm),
                AppIcon(rtl ? AppIcons.back : AppIcons.forward, size: IconSizes.medium, color: theme.palette.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (TapDownDetails _) => _set(true) : null,
        onTapUp: enabled ? (TapUpDetails _) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onPressed,
        child: row,
      ),
    );
  }
}
