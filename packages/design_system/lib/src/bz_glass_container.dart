import 'dart:ui';

import 'package:flutter/material.dart';

import 'bz_theme.dart';

/// BzGlassContainer — the one glass surface every floating widget uses.
///
/// Translucent fill + backdrop blur + hairline border. Degrades to a
/// solid surface automatically when platform reduced-transparency /
/// accessibility settings ask for it.
class BzGlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final Color? fillColor;
  final Color? borderColor;

  const BzGlassContainer({
    super.key,
    required this.child,
    required this.radius,
    this.blur = 24,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.bz;
    final media = MediaQuery.of(context);
    final reduce = media.disableAnimations || media.boldText;

    final fill = fillColor ?? colors.atmoRegular;
    final border = borderColor ?? colors.separator;

    if (reduce) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surface1,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border),
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
