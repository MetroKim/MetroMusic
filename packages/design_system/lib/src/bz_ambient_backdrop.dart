import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'bz_theme.dart';

/// BzAmbientBackdrop — content is the colour (Liner principle, Breezze
/// execution). Artwork blooms softly behind the screen chrome.
class BzAmbientBackdrop extends StatelessWidget {
  final Widget child;
  final String? artworkUrl;

  const BzAmbientBackdrop({
    super.key,
    required this.child,
    this.artworkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bz;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: colors.background),
        if (artworkUrl != null)
          Image.network(
            artworkUrl!,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.35),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            color: colors.background.withOpacity(0.55),
          ),
        ),
        child,
      ],
    );
  }
}
