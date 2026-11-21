import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../app/downloads_controller.dart';
import '../../widgets/bz_brand_icons.dart';
import '../player/player_controller.dart';
import 'video_detail_screen.dart';

/// Search screen — Songs / Videos segmented search over the live
/// source (§04), skeleton loading, honest empty state.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<BzTrack> _songs = [];
  List<BzVideo> _videos = [];
  var _loading = false;
  var _searched = false;
  int _segment = 0; // 0 = Songs, 1 = Videos

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
      _songs = [];
      _videos = [];
    });

    final source = ref.read(youtubeSourceProvider);
    final songOp = await source.search(query.trim());

    // Video search — best effort; failures leave Videos empty but
    // never block song results (§04: stale/failed requests never
    // present as fresh results).
    final videoOp = await source.searchVideos(query.trim());

    if (!mounted) return;
    setState(() {
      _loading = false;
      _songs = songOp is ProviderOk<List<ProviderTrack>>
          ? songOp.value
              .map((t) => BzTrack(
                    id: t.breezzeTrackId,
                    title: t.title,
                    artist: t.artist,
                    artworkUrl: t.artworkUrl,
                    duration: t.duration,
                  ))
              .toList()
          : [];
      _videos = videoOp is ProviderOk<List<BzVideo>> ? videoOp.value : [];
    });
  }

  void _download(BzTrack track) {
    ref.read(downloadProgressProvider.notifier).download(track);
  }

  void _play(BzTrack track) {
    final queue = [
      for (final t in _songs)
        TrackInfo(
          id: t.id,
          title: t.title,
          artist: t.artist,
          artworkUrl: t.artworkUrl,
          duration: t.duration,
        )
    ];
    final index = _songs.indexOf(track);
    ref.read(playerControllerProvider.notifier).playTrack(
          trackId: track.id,
          queue: queue,
          startIndex: index.clamp(0, queue.length - 1),
          origin: 'search',
          sourceContext: 'Search',
        );
  }

  void _openVideo(BzVideo video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoDetailScreen(video: video),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ref.watch(downloadProgressProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: TextField(
              controller: _controller,
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search songs, videos, artists…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.bzFillSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BzRadius.input),
                  borderSide: BorderSide(color: theme.bzSeparator),
                ),
              ),
            ),
          ),
          if (_searched)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BzSegmentedControl(
                  segments: const ['Songs', 'Videos'],
                  activeIndex: _segment,
                  onChanged: (i) => setState(() => _segment = i),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 220),
                    children: [
                      for (var i = 0; i < 8; i++)
                        const BzSkeletonTrackRow(),
                    ],
                  )
                : !_searched
                    ? Center(
                        child: BzBnoteMark(size: 64, color: theme.bzText2),
                      )
                    : _segment == 0
                        ? _songs.isEmpty
                            ? _Empty(
                                message: 'No songs found',
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 8, 0, 220),
                                itemCount: _songs.length,
                                itemBuilder: (context, i) {
                                  final track = _songs[i];
                                  final p = progress[track.id];
                                  return ListTile(
                                    leading: track.artworkUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    BzRadius.artwork),
                                            child: Image.network(
                                              track.artworkUrl!,
                                              width: 48,
                                              height: 48,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      BzBnoteMark(
                                                          size: 48,
                                                          color:
                                                              theme.bzText2),
                                            ),
                                          )
                                        : BzBnoteMark(
                                            size: 48, color: theme.bzText2),
                                    title: Text(track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: p != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: p,
                                              minHeight: 3,
                                              backgroundColor:
                                                  theme.bzSeparator,
                                              color: theme.bzAccent,
                                            ),
                                          )
                                        : Text(track.artist,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis),
                                    trailing: p != null
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                                Icons.download_outlined),
                                            onPressed: () =>
                                                _download(track),
                                          ),
                                    onTap: () => _play(track),
                                  );
                                },
                              )
                        : _videos.isEmpty
                            ? const _Empty(message: 'No videos found')
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 8, 0, 220),
                                itemCount: _videos.length,
                                itemBuilder: (context, i) {
                                  final video = _videos[i];
                                  return ListTile(
                                    leading: video.thumbnailUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    BzRadius.artwork),
                                            child: Stack(
                                              children: [
                                                Image.network(
                                                  video.thumbnailUrl!,
                                                  width: 64,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          Container(
                                                    width: 64,
                                                    height: 40,
                                                    color: theme.bzFillBase,
                                                    child: BzBnoteMark(
                                                        size: 24,
                                                        color:
                                                            theme.bzText2),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 2,
                                                  right: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4,
                                                        vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .bzBackground
                                                          .withOpacity(0.85),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              3),
                                                    ),
                                                    child: Text(
                                                      _fmt(video.duration),
                                                      style: TextStyle(
                                                        fontSize:
                                                            BzType.caption,
                                                        color: theme.bzText1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container(
                                            width: 64,
                                            height: 40,
                                            color: theme.bzFillBase,
                                            child: BzBnoteMark(
                                                size: 24,
                                                color: theme.bzText2),
                                          ),
                                    title: Text(video.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Text(video.channel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    trailing: const Icon(Icons
                                        .play_circle_outline_rounded),
                                    onTap: () => _openVideo(video),
                                  );
                                },
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

/// Honest empty state — never a fake spinner or placeholder data.
class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BzBnoteMark(size: 56, color: theme.bzText2),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
