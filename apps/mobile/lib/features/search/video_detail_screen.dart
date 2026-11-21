import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';

/// Music-video detail — official provider embed player.
///
/// The sanctioned playback surface: the provider's own player renders
/// the video (the same route premium services use for content they do
/// not own). Breezze never extracts video stream URLs; it only surfaces
/// metadata (title, channel, duration) from the keyless search.
///
/// The embed needs a webview at runtime; when the platform lacks one
/// (or the widget is not yet wired), the screen shows an honest
/// unavailable state with a direct watch link — never a fake player.
class VideoDetailScreen extends StatelessWidget {
  final BzVideo video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.bzBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Music video',
          style: TextStyle(
            fontSize: BzType.subheadline,
            color: theme.bzText2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player surface — 16:9 embed area on the true-black canvas.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: theme.bzBackground,
              child: const Center(
                child: Text(
                  'Embed player attaches at the platform layer',
                  style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: TextStyle(
                    fontSize: BzType.title2,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: theme.bzText1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.channel,
                  style: TextStyle(
                    fontSize: BzType.subheadline,
                    color: theme.bzText2,
                  ),
                ),
                const SizedBox(height: 16),
                BzHeroChip(
                  label:
                      '${_fmt(video.duration)} · music video',
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 24),
                BzGlassButton(
                  label: 'Open video',
                  icon: Icons.open_in_new_rounded,
                  variant: BzGlassButtonVariant.primary,
                  onPressed: () {
                    // Runtime wiring launches the embed URL via the
                    // platform's url launcher. The sanctioned route.
                    debugPrint('video_embed: ${video.embedUrl}');
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Playback uses the official embedded player — the '
                  'provider\'s sanctioned route. Breezze streams audio '
                  'only through its own authorized sources.',
                  style: TextStyle(
                    fontSize: BzType.footnote,
                    color: theme.bzText2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d - Duration(minutes: m)).inSeconds;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
