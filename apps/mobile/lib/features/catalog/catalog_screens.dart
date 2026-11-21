import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:breezze_design_system/breezze_design_system.dart';

import '../player/player_controller.dart';
import '../downloads/downloads_screen.dart';

/// Browse destination. Catalog-backed sections remain empty until a
/// CatalogRepository is connected; this avoids presenting sample data as real.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String _selected = 'For You';

  static const _categories = [
    'For You', 'New Releases', 'Charts', 'Genres',
    'Moods & Activities', 'Music Videos', 'Concerts',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Text('Browse', style: theme.textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Find your next favorite.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = _categories[index];
                final selected = value == _selected;
                return ChoiceChip(
                  label: Text(value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = value),
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
          const SizedBox(height: 28),
          _CatalogEmptyState(
            icon: Icons.explore_outlined,
            title: _selected + ' is ready to explore',
            message: 'Connect a catalog provider to load verified releases, '
                'charts, genres and editorial collections here.',
          ),
        ],
      ),
    );
  }
}

/// Radio destination. Live status is never fabricated.
class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Text('Radio', style: theme.textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Stations, shows and live broadcasts.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          _CatalogEmptyState(
            icon: Icons.radio_outlined,
            title: 'No stations connected',
            message: 'When a licensed radio source is configured, featured '
                'stations, live status and show schedules will appear here.',
          ),
        ],
      ),
    );
  }
}

/// Library destination with user-owned sections and an honest first-run state.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _section = 'Playlists';

  static const _sections = [
    'Playlists', 'Artists', 'Albums', 'Songs', 'Genres', 'Compilations', 'Downloads',
  ];

  @override
  Widget build(BuildContext context) {
    if (_section == 'Downloads') return const DownloadsScreen();
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Library', style: theme.textTheme.displayMedium),
              ),
              IconButton(
                tooltip: 'Library options',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Library organization options will be '
                          'available when library persistence is connected.'),
                    ),
                  ),
                ),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final section in _sections)
                ChoiceChip(
                  label: Text(section),
                  selected: _section == section,
                  onSelected: (_) => setState(() => _section = section),
                  selectedColor: theme.bzText1,
                  backgroundColor: theme.bzSurface1,
                  labelStyle: TextStyle(
                    color: _section == section
                        ? theme.bzBackground
                        : theme.bzText1,
                  ),
                  side: BorderSide(color: theme.bzSeparator),
                ),
            ],
          ),
          const SizedBox(height: 28),
          _CatalogEmptyState(
            icon: Icons.library_music_outlined,
            title: 'Your ' + _section + ' will live here',
            message: 'Save music from Browse or Search to build your '
                'personal library. Your collection will stay separate '
                'from offline downloads.',
          ),
        ],
      ),
    );
  }
}

/// Global search UI. SearchRepository integration is a separate catalog task.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Text('Search', style: theme.textTheme.displayMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            onChanged: (value) => setState(() => _query = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Songs, artists, albums and more',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: theme.bzSurface1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BzRadius.card),
                borderSide: BorderSide(color: theme.bzSeparator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BzRadius.card),
                borderSide: BorderSide(color: theme.bzSeparator),
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (_query.isEmpty)
            _CatalogEmptyState(
              icon: Icons.manage_search,
              title: 'Search the catalog',
              message: 'Find tracks, albums, artists and playlists once a '
                  'catalog search provider is connected.',
            )
          else
            _CatalogEmptyState(
              icon: Icons.search_off,
              title: 'Search is not connected yet',
              message: 'Your search for "' + _query + '" is ready. Connect the '
                  'SearchRepository to return real catalog results.',
            ),
        ],
      ),
    );
  }
}

/// Full player surface backed by the one global PlayerController.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final theme = Theme.of(context);
    final isPlaying = player.playbackState == PlaybackState.playing;
    final active = player.playbackState != PlaybackState.idle;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.bzSeparator,
                borderRadius: BorderRadius.circular(BzRadius.capsule),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.bzText2,
                fontSize: BzType.footnote,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 28),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: theme.bzSurface1,
                borderRadius: BorderRadius.circular(BzRadius.modal),
                border: Border.all(color: theme.bzSeparator),
              ),
              child: Center(
                child: Icon(Icons.music_note,
                    size: 88, color: theme.bzText2),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            active ? 'Playback session' : 'Nothing playing yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? 'Track metadata will appear when the catalog is connected.'
                : 'Choose a track from Browse or Search to start listening.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          Slider(
            value: player.duration.inMilliseconds <= 0
                ? 0
                : player.position.inMilliseconds
                    .clamp(0, player.duration.inMilliseconds)
                    .toDouble(),
            max: player.duration.inMilliseconds <= 0
                ? 1
                : player.duration.inMilliseconds.toDouble(),
            onChanged: player.duration == Duration.zero
                ? null
                : (value) => controller.seekTo(
                      Duration(milliseconds: value.round()),
                    ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(player.position),
                  style: theme.textTheme.bodySmall),
              Text(_formatDuration(player.duration),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Shuffle',
                onPressed: active ? controller.toggleShuffle : null,
                icon: const Icon(Icons.shuffle),
                iconSize: 24,
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Previous track',
                onPressed: active ? controller.previous : null,
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 36,
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: active ? controller.togglePlayPause : null,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(18),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Next track',
                onPressed: active ? controller.next : null,
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 36,
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Repeat',
                onPressed: active ? controller.cycleRepeat : null,
                icon: const Icon(Icons.repeat),
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: theme.bzSeparator),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Playing Next'),
            subtitle: const Text('Queue controls will be available with '
                'the catalog queue interface.'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.lyrics_outlined),
            title: const Text('Lyrics'),
            subtitle: const Text('Lyrics appear when a licensed provider '
                'returns a matching track.'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _CatalogEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CatalogEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: theme.bzSurface1,
        borderRadius: BorderRadius.circular(BzRadius.card),
        border: Border.all(color: theme.bzSeparator),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: theme.bzText2),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
