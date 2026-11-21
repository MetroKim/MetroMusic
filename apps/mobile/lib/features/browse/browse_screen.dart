import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../app/downloads_controller.dart';
import '../../features/player/player_controller.dart';
import '../../widgets/bz_brand_icons.dart';

/// Browse uses live source search for genre discovery. It does not label
/// provider search results as official charts or editorial recommendations.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  static const _genres = [
    'Afrobeats',
    'Bongo Flava',
    'Amapiano',
    'Gospel',
    'Hip-Hop',
    'R&B',
    'Jazz',
    'Electronic',
  ];

  String _selectedGenre = _genres.first;
  List<BzTrack> _tracks = [];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadGenre(_selectedGenre);
    });
  }

  Future<void> _loadGenre(String genre) async {
    final requestId = ++_requestId;
    setState(() {
      _selectedGenre = genre;
      _loading = true;
      _error = null;
      _tracks = [];
    });

    try {
      final result = await ref.read(youtubeSourceProvider).search('$genre music');
      if (!mounted || requestId != _requestId) return;

      if (result is ProviderOk<List<ProviderTrack>>) {
        setState(() {
          _tracks = result.value
              .map((track) => BzTrack(
                    id: track.breezzeTrackId,
                    title: track.title,
                    artist: track.artist,
                    artworkUrl: track.artworkUrl,
                    duration: track.duration,
                  ))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'This music source could not return results right now.';
        });
      }
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = 'Could not connect to the music source. Try again.';
      });
    }
  }

  void _play(int index) {
    if (_tracks.isEmpty) return;
    final queue = [
      for (final track in _tracks)
        TrackInfo(
          id: track.id,
          title: track.title,
          artist: track.artist,
          artworkUrl: track.artworkUrl,
          duration: track.duration,
        ),
    ];
    ref.read(playerControllerProvider.notifier).playTrack(
          trackId: _tracks[index].id,
          queue: queue,
          startIndex: index,
          origin: 'browse',
          sourceContext: _selectedGenre,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ref.watch(downloadProgressProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Browse', style: theme.textTheme.displayMedium),
                const SizedBox(height: 6),
                Text('Explore music by genre.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _genres.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final genre = _genres[index];
                      final selected = genre == _selectedGenre;
                      return ChoiceChip(
                        label: Text(genre),
                        selected: selected,
                        onSelected: (_) => _loadGenre(genre),
                        selectedColor: theme.bzText1,
                        backgroundColor: theme.bzSurface1,
                        labelStyle: TextStyle(
                          color: selected ? theme.bzBackground : theme.bzText1,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(color: theme.bzSeparator),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _MessageState(
                        icon: Icons.wifi_off,
                        title: 'Music is unavailable',
                        message: _error!,
                        onRetry: () => _loadGenre(_selectedGenre),
                      )
                    : _tracks.isEmpty
                        ? _MessageState(
                            icon: Icons.music_note_outlined,
                            title: 'No tracks found',
                            message: 'Try another genre or search for an artist.',
                            onRetry: () => _loadGenre(_selectedGenre),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 220),
                            itemCount: _tracks.length,
                            itemBuilder: (context, index) {
                              final track = _tracks[index];
                              final download = progress[track.id];
                              return ListTile(
                                leading: track.artworkUrl == null
                                    ? BzBnoteMark(
                                        size: 48, color: theme.bzText2)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            BzRadius.artwork),
                                        child: Image.network(
                                          track.artworkUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              BzBnoteMark(
                                            size: 48,
                                            color: theme.bzText2,
                                          ),
                                        ),
                                      ),
                                title: Text(track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                trailing: download != null
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : IconButton(
                                        tooltip: 'Download',
                                        icon: const Icon(
                                            Icons.download_outlined),
                                        onPressed: () => ref
                                            .read(downloadProgressProvider
                                                .notifier)
                                            .download(track),
                                      ),
                                onTap: () => _play(index),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: theme.bzText2),
            const SizedBox(height: 14),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
