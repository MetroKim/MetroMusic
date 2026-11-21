import 'package:flutter/material.dart';

import 'bz_glass_container.dart';
import 'bz_theme.dart';
import 'tokens.dart';

/// BzHeroChip — the meta pill on artwork-driven heroes (track count ·
/// duration). Glass tint so it reads as part of the cover surface.
class BzHeroChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const BzHeroChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.bzFillBase,
        borderRadius: BorderRadius.circular(BzRadius.button),
        border: Border.all(color: theme.bzSeparator),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.bzText2),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: BzType.footnote,
              fontWeight: FontWeight.w500,
              color: theme.bzText2,
            ),
          ),
        ],
      ),
    );
  }
}

/// BzGlassButton — the hero action button. Two variants:
/// - [BzGlassButtonVariant.primary]: inverted text button (Play all).
/// - [BzGlassButtonVariant.glass]: frosted glass (Shuffle, secondary).
class BzGlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final BzGlassButtonVariant variant;

  const BzGlassButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.variant = BzGlassButtonVariant.primary,
  });

  @override
  State<BzGlassButton> createState() => _BzGlassButtonState();
}

enum BzGlassButtonVariant { primary, glass }

class _BzGlassButtonState extends State<BzGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = widget.variant == BzGlassButtonVariant.primary;
    final disabled = widget.onPressed == null;

    final bg = isPrimary
        ? (disabled ? theme.bzSeparator : theme.bzText1)
        : (_pressed ? theme.bzFillStrong : theme.bzFillBase);
    final fg = isPrimary ? theme.bzBackground : theme.bzText1;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: BzMotion.instantMs),
        curve: BzMotion.standardCurve,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: BzMotion.fastMs),
          curve: BzMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(BzRadius.button),
            border: isPrimary
                ? null
                : Border.all(color: theme.bzSeparator),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: BzType.subheadline,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
