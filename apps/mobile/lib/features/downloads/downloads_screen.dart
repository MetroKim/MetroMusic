import 'dart:io';

import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../app/downloads_controller.dart';
import '../../widgets/bz_brand_icons.dart';
import '../player/player_controller.dart';

/// Downloads library — offline tracks with cover art + lyrics, plus a
/// live in-progress section (§6.1).
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  List<DownloadedTrack> _tracks = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final dir = await downloadsDirectory();
    final library = DownloadsLibrary(
      root: dir,
      lyrics: ref.read(lyricsProvider),
    );
    final tracks = await library.list();
    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _loading = false;
    });
  }

  void _play(DownloadedTrack track) {
    ref.read(playerControllerProvider.notifier).playTrack(
          trackId: track.trackId,
          title: track.title,
          artist: track.artist,
          origin: 'downloads',
          sourceContext: 'Downloads',
        );
  }

  Future<void> _remove(DownloadedTrack track) async {
    final dir = await downloadsDirectory();
    await DownloadsLibrary(
      root: dir,
      lyrics: ref.read(lyricsProvider),
    ).remove(track.trackId);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ref.watch(downloadProgressProvider);
    final inProgress = progress.entries.toList();

    // Refresh the completed list when the last in-flight download ends.
    if (inProgress.isEmpty && _tracks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfNeeded());
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Downloads',
                      style: theme.textTheme.displayMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 220),
                    children: [
                      // In-progress section (live)
                      for (final entry in inProgress)
                        ListTile(
                          leading: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          ),
                          title: Text(
                              'Downloading… ${(entry.value * 100).round()}%',
                              style: theme.textTheme.titleMedium),
                          subtitle: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: entry.value,
                              minHeight: 3,
                              backgroundColor: theme.bzSeparator,
                              color: theme.bzAccent,
                            ),
                          ),
                        ),
                      // Completed downloads
                      if (_tracks.isEmpty && inProgress.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),
                              BzBnoteMark(size: 64, color: theme.bzText2),
                              const SizedBox(height: 16),
                              Text('No downloads yet',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                  'Search a song and tap the download icon.',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        )
                      else
                        for (final track in _tracks)
                          ListTile(
                            leading: track.coverPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        BzRadius.artwork),
                                    child: Image.file(
                                      File(track.coverPath!),
                                      width: 48,
                                      height: 48,
                                      errorBuilder: (_, __, ___) =>
                                          BzBnoteMark(
                                              size: 48, color: theme.bzText2),
                                    ),
                                  )
                                : BzBnoteMark(size: 48, color: theme.bzText2),
                            title: Text(track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${track.artist}'
                              '${track.lyricsPath != null ? ' · lyrics saved' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _remove(track),
                                ),
                                const Icon(Icons.download_done,
                                    color: Colors.green),
                              ],
                            ),
                            onTap: () => _play(track),
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  var _refreshedAt = 0;

  void _refreshIfNeeded() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _refreshedAt < 1000) return; // throttle
    _refreshedAt = now;
    _refresh();
  }
}
