import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../widgets/bz_brand_icons.dart';
import '../player/player_controller.dart';

/// Now Playing — premium edition: ambient artwork backdrop (content is
/// the colour), breathing artwork on the calm 2s loop, word-synced
/// karaoke lyrics with active-line scale and edge fog.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Lyrics? _lyrics;
  String _lyricsMode = 'none';

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final track = ref.read(playerControllerProvider).currentTrack;
    if (track == null || track.title == null) return;
    final result = await ref.read(lyricsProvider).bestFor(BzTrack(
          id: track.id,
          title: track.title!,
          artist: track.artist ?? '',
          duration: track.duration,
        ));
    if (!mounted) return;
    if (result == null) {
      setState(() => _lyricsMode = 'none');
      return;
    }
    final synced = result.syncedLrc != null;
    setState(() {
      _lyrics = LrcParser.parse(track.id, result.bestLrc);
      _lyricsMode = synced ? 'synced' : 'plain';
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = (d - Duration(minutes: m)).inSeconds;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final theme = Theme.of(context);
    final track = player.currentTrack;
    final playing = player.playbackState == PlaybackState.playing;

    if (track == null) {
      return Scaffold(
        backgroundColor: theme.bzBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BzBnoteMark(size: 72, color: theme.bzText2),
              const SizedBox(height: 16),
              Text('Nothing playing', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: BzAmbientBackdrop(
        artworkUrl: track.artworkUrl,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('PLAYING FROM',
                              style: TextStyle(
                                  fontSize: BzType.caption,
                                  letterSpacing: 1,
                                  color: theme.bzText2)),
                          Text('Breezze',
                              style: TextStyle(
                                  fontSize: BzType.footnote,
                                  color: theme.bzText1)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _BreathingArtwork(
                playing: playing,
                artworkUrl: track.artworkUrl,
                fallbackColor: theme.bzText2,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title ?? 'Unknown track',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(track.artist ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: BzType.body,
                                  color: theme.bzText2)),
                        ],
                      ),
                    ),
                    _FavoriteButton(track: track),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: player.duration > Duration.zero
                            ? player.position.inMilliseconds
                                .clamp(0, player.duration.inMilliseconds)
                                .toDouble()
                            : 0,
                        max: player.duration.inMilliseconds > 0
                            ? player.duration.inMilliseconds.toDouble()
                            : 1,
                        onChanged: (v) => controller
                            .seekTo(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(player.position),
                            style: TextStyle(
                                fontSize: BzType.caption,
                                color: theme.bzText2)),
                        Text(_format(player.duration),
                            style: TextStyle(
                                fontSize: BzType.caption,
                                color: theme.bzText2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: controller.toggleShuffle,
                    color: theme.bzText2,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 36),
                    onPressed: controller.previous,
                  ),
                  const SizedBox(width: 16),
                  _PlayPauseButton(
                    playing: playing,
                    size: 64,
                    onTap: controller.togglePlayPause,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 36),
                    onPressed: controller.next,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.repeat),
                    onPressed: controller.cycleRepeat,
                    color: theme.bzText2,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _LyricsView(
                  lyrics: _lyrics,
                  mode: _lyricsMode,
                  position: player.position,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingArtwork extends StatefulWidget {
  final bool playing;
  final String? artworkUrl;
  final Color fallbackColor;

  const _BreathingArtwork({
    required this.playing,
    required this.artworkUrl,
    required this.fallbackColor,
  });

  @override
  State<_BreathingArtwork> createState() => _BreathingArtworkState();
}

class _BreathingArtworkState extends State<_BreathingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
    lowerBound: 0.96,
    upperBound: 1.0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BreathingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bz;
    return ScaleTransition(
      scale: _controller,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(BzRadius.artwork),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BzRadius.artwork),
          child: widget.artworkUrl != null
              ? Image.network(
                  widget.artworkUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: BzBnoteMark(size: 96, color: widget.fallbackColor),
                  ),
                )
              : Center(
                  child: BzBnoteMark(size: 96, color: widget.fallbackColor),
                ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool playing;
  final double size;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.playing,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.bzText1,
          shape: BoxShape.circle,
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          color: theme.bzBackground,
          size: size * 0.55,
        ),
      ),
    );
  }
}

/// Lyrics view — BzLyricLine states inside the fogged list (edge fog
/// lifts at the scroll ends on the token curve). Word-synced lines keep
/// the karaoke word wrap; plain lines use BzLyricLine directly.
class _LyricsView extends StatelessWidget {
  final Lyrics? lyrics;
  final String mode;
  final Duration position;

  const _LyricsView({
    required this.lyrics,
    required this.mode,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (mode == 'none' || lyrics == null || lyrics!.lines.isEmpty) {
      return Center(
        child: Text(
          'No lyrics available for this track',
          style: TextStyle(fontSize: BzType.subheadline, color: theme.bzText2),
        ),
      );
    }

    final activeIndex = lyrics!.activeLineIndex(position);
    final isSynced = mode == 'synced';

    return BzFoggedListView(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
      itemCount: lyrics!.lines.length,
      itemBuilder: (context, i) {
        final line = lyrics!.lines[i];
        final active = i == activeIndex;
        final activeWord =
            active && isSynced ? lyrics!.activeWordIndex(i, position) : -1;

        // Word-synced karaoke wrap for lines with word timings.
        if (line.words.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
            child: Wrap(
              children: [
                for (var w = 0; w < line.words.length; w++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: BzType.headline,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                        color: active
                            ? (w <= activeWord
                                ? theme.bzText1
                                : theme.bzText2)
                            : theme.bzText2,
                      ),
                      child: Text(line.words[w].text),
                    ),
                  ),
              ],
            ),
          );
        }

        // Plain / line-synced: the shared BzLyricLine component.
        return BzLyricLine(
          text: line.text,
          active: active,
        );
      },
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final TrackInfo track;

  const _FavoriteButton({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.favorite_border),
      onPressed: () async {
        final added = await ref.read(favoritesStoreProvider).toggle(
              FavoriteTrack(
                id: track.id,
                title: track.title ?? '',
                artist: track.artist ?? '',
                artworkUrl: track.artworkUrl,
                durationMs: track.duration.inMilliseconds,
              ),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(added ? 'Added to favorites' : 'Removed from favorites')));
        }
      },
    );
  }
}
