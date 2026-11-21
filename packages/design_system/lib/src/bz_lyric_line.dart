import 'package:flutter/material.dart';

import 'bz_theme.dart';
import 'tokens.dart';

/// BzLyricLine — one line of synchronized lyrics.
///
/// Three states on the token curve: inactive (small, dimmed, softly
/// blurred), hover (nearly full), active (full size, full contrast,
/// sharp). Tapping seeks via [onTap]. Respects reduced-motion.
class BzLyricLine extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback? onTap;
  final bool emphasize;

  /// Word-synced highlight progress within the line, 0.0–1.0.
  /// Null disables the word sweep.
  final double? wordProgress;

  const BzLyricLine({
    super.key,
    required this.text,
    required this.active,
    this.onTap,
    this.emphasize = false,
    this.wordProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final scale = active ? 1.03 : 0.96;
    final opacity = active ? 1.0 : 0.38;
    final sigma = active ? 0.0 : 0.4;
    final color = active
        ? theme.bzText1
        : (emphasize ? theme.bzText2 : theme.bzText2);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: BzType.title2,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            height: 1.25,
            color: color,
          ),
        ),
      ),
    );

    final line = GestureDetector(
      onTap: onTap,
      child: reduceMotion
          ? Opacity(
              opacity: opacity,
              child: content,
            )
          : AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 320),
              curve: BzMotion.standardCurve,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 320),
                curve: BzMotion.standardCurve,
                opacity: opacity,
                child: sigma > 0
                    ? ImageFiltered(
                        imageFilter: ImageFilter.blur(
                            sigmaX: sigma, sigmaY: sigma),
                        child: content,
                      )
                    : content,
              ),
            ),
    );

    // Word-synced sweep: a light fill washes over the active line.
    if (active && wordProgress != null && !reduceMotion) {
      return ClipRRect(
        child: Stack(
          children: [
            line,
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Colors.transparent,
                    Colors.white,
                    Colors.transparent
                  ],
                  stops: const [0.0, 1.0, 1.0],
                ).createShader(bounds),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (wordProgress!).clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear,
                  builder: (context, p, child) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: p,
                    child: child!,
                  ),
                  child: ColoredBox(
                    color: theme.bzText1.withOpacity(0.05),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return line;
  }
}
