import 'package:flutter/material.dart';

import 'bz_theme.dart';

/// BzSkeleton — loading placeholder with the Breezze shimmer.
///
/// Two layered animations on the token curve: a slow opacity breathe
/// and a diagonal light sweep across the fill. Respects reduced-motion
/// by falling back to a static fill.
class BzSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const BzSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 4,
  });

  @override
  State<BzSkeleton> createState() => _BzSkeletonState();
}

class _BzSkeletonState extends State<BzSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.bzSeparator,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: Stack(
            children: [
              // Base quiet fill
              Positioned.fill(
                child: ColoredBox(
                  color: Color.lerp(
                    theme.bzSeparator,
                    theme.bzFillStrong,
                    0.35 + 0.3 * (0.5 - (0.5 - ((t * 2) % 1 - 0.5).abs())),
                  )!,
                ),
              ),
              // Diagonal light sweep
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    final sweepCenter = -0.6 + t * 2.2;
                    return LinearGradient(
                      begin: Alignment(sweepCenter - 0.35, -1),
                      end: Alignment(sweepCenter + 0.35, 1),
                      colors: [
                        Colors.transparent,
                        theme.bzFillHover,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  child: ColoredBox(color: theme.bzText1.withOpacity(0.06)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A full skeleton row for track lists — artwork square + two lines.
class BzSkeletonTrackRow extends StatelessWidget {
  const BzSkeletonTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          BzSkeleton(width: 48, height: 48, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BzSkeleton(height: 14, width: 220),
                SizedBox(height: 8),
                BzSkeleton(height: 10, width: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton grid cell for card rails.
class BzSkeletonCard extends StatelessWidget {
  final double size;

  const BzSkeletonCard({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BzSkeleton(width: size, height: size, radius: 12),
          const SizedBox(height: 8),
          const BzSkeleton(height: 12, width: 120),
          const SizedBox(height: 6),
          const BzSkeleton(height: 10, width: 80),
        ],
      ),
    );
  }
}
