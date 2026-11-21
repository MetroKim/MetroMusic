import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../widgets/bz_brand_icons.dart';
import '../player/player_controller.dart';

/// Library — favorites persisted locally (§6.2).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<FavoriteTrack> _favorites = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final favorites = await ref.read(favoritesStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _loading = false;
    });
  }

  List<TrackInfo> _queue() => [
        for (final f in _favorites)
          TrackInfo(
            id: f.id,
            title: f.title,
            artist: f.artist,
            artworkUrl: f.artworkUrl,
            duration: Duration(milliseconds: f.durationMs),
          )
      ];

  void _playAll() {
    if (_favorites.isEmpty) return;
    ref.read(playerControllerProvider.notifier).playTrack(
          trackId: _favorites.first.id,
          queue: _queue(),
          origin: 'library',
          sourceContext: 'Favorites',
        );
  }

  void _playOne(int index) {
    ref.read(playerControllerProvider.notifier).playTrack(
          trackId: _favorites[index].id,
          queue: _queue(),
          startIndex: index,
          origin: 'library',
          sourceContext: 'Favorites',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text('Library', style: theme.textTheme.displayMedium)),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
              ],
            ),
          ),
          if (_favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ElevatedButton.icon(
                onPressed: _playAll,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play favorites'),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _favorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BzBnoteMark(size: 64, color: theme.bzText2),
                            const SizedBox(height: 16),
                            Text('No favorites yet',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                                'Tap the heart on Now Playing to save songs here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 220),
                        itemCount: _favorites.length,
                        itemBuilder: (context, i) {
                          final fav = _favorites[i];
                          return ListTile(
                            leading: fav.artworkUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        BzRadius.artwork),
                                    child: Image.network(
                                      fav.artworkUrl!,
                                      width: 48,
                                      height: 48,
                                      errorBuilder: (_, __, ___) =>
                                          BzBnoteMark(
                                              size: 48, color: theme.bzText2),
                                    ),
                                  )
                                : BzBnoteMark(size: 48, color: theme.bzText2),
                            title: Text(fav.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(fav.artist,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => _playOne(i),
                            trailing: IconButton(
                              icon: const Icon(Icons.favorite,
                                  color: Colors.redAccent),
                              onPressed: () async {
                                await ref
                                    .read(favoritesStoreProvider)
                                    .toggle(fav);
                                _refresh();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
