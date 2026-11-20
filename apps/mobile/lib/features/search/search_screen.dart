import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../app/downloads_controller.dart';
import '../../widgets/bz_brand_icons.dart';
import '../player/player_controller.dart';

/// Search screen — real results from the live source (§04), with live
/// download progress.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<BzTrack> _results = [];
  var _loading = false;
  var _searched = false;

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
    });
    final op = await ref.read(youtubeSourceProvider).search(query.trim());
    setState(() {
      _loading = false;
      _results = op is ProviderOk<List<ProviderTrack>>
          ? op.value
              .map((t) => BzTrack(
                    id: t.breezzeTrackId,
                    title: t.title,
                    artist: t.artist,
                    artworkUrl: t.artworkUrl,
                    duration: t.duration,
                  ))
              .toList()
          : [];
    });
  }

  void _download(BzTrack track) {
    ref.read(downloadProgressProvider.notifier).download(track);
  }

  void _play(BzTrack track) {
    final queue = [
      for (final t in _results)
        TrackInfo(
          id: t.id,
          title: t.title,
          artist: t.artist,
          artworkUrl: t.artworkUrl,
          duration: t.duration,
        )
    ];
    final index = _results.indexOf(track);
    ref.read(playerControllerProvider.notifier).playTrack(
          trackId: track.id,
          queue: queue,
          startIndex: index.clamp(0, queue.length - 1),
          origin: 'search',
          sourceContext: 'Search',
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
                hintText: 'Search songs, artists…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.bzSurface1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BzRadius.input),
                  borderSide: BorderSide(color: theme.bzSeparator),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? Center(
                        child: BzBnoteMark(size: 64, color: theme.bzText2),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text('No results',
                                style: theme.textTheme.titleMedium),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 220),
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final track = _results[i];
                              final p = progress[track.id];
                              return ListTile(
                                leading: track.artworkUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            BzRadius.artwork),
                                        child: Image.network(
                                          track.artworkUrl!,
                                          width: 48,
                                          height: 48,
                                          errorBuilder: (_, __, ___) =>
                                              BzBnoteMark(
                                                  size: 48,
                                                  color: theme.bzText2),
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
                                        overflow: TextOverflow.ellipsis),
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
                          ),
          ),
        ],
      ),
    );
  }
}
