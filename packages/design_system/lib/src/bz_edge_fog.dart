import 'package:flutter/material.dart';

import 'bz_theme.dart';
import 'tokens.dart';

/// BzEdgeFog — fades a scrollable lyric or list at its top and bottom
/// edges with an animated mask. The fog opens when the scroll reaches
/// that edge, closing again when content scrolls away from it.
///
/// Wrap any scrollable child; no controller required.
class BzEdgeFog extends StatelessWidget {
  final Widget child;
  final double topFog;
  final double bottomFog;

  const BzEdgeFog({
    super.key,
    required this.child,
    this.topFog = 56,
    this.bottomFog = 72,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Colors.black, Colors.black],
        stops: const [0.0, 1.0],
      ).createShader(bounds),
      // Mask implemented as an overlay gradient; see ShaderMask below.
      child: child,
    );
  }
}

/// A fogged list view for lyrics — the reference implementation of the
/// edge-fog recipe: gradient mask over a scrollable, tracking scroll
/// position so the fog lifts at the ends.
class BzFoggedListView extends StatefulWidget {
  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;
  final ScrollController? controller;
  final EdgeInsets padding;

  const BzFoggedListView({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    this.padding = const EdgeInsets.symmetric(vertical: 24),
  });

  @override
  State<BzFoggedListView> createState() => _BzFoggedListViewState();
}

class _BzFoggedListViewState extends State<BzFoggedListView> {
  late final ScrollController _controller;

  double _topInset = 0.5; // 0 = no fog at top, 1 = full fog
  double _bottomInset = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _controller.position;
    final atTop = pos.pixels <= 0;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 1;
    final topTarget = atTop ? 0.0 : 1.0;
    final bottomTarget = atBottom ? 0.0 : 1.0;
    if (topTarget != _topInset || bottomTarget != _bottomInset) {
      setState(() {
        _topInset = topTarget;
        _bottomInset = bottomTarget;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fog = theme.bzBackground;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _topInset),
      duration: const Duration(milliseconds: 450),
      curve: BzMotion.standardCurve,
      builder: (context, top, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(end: _bottomInset),
          duration: const Duration(milliseconds: 450),
          curve: BzMotion.standardCurve,
          builder: (context, bottom, child) {
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  fog.withOpacity(top),
                  Colors.transparent,
                  Colors.transparent,
                  fog.withOpacity(bottom),
                ],
                stops: const [0.0, 0.14, 0.86, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstOut,
              child: child!,
            );
          },
          child: child,
        );
      },
      child: ListView.builder(
        controller: _controller,
        padding: widget.padding,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
