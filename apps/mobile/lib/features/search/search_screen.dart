import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../app/downloads_controller.dart';
import '../../app/search_history_store.dart';
import '../../widgets/bz_brand_icons.dart';
import '../player/player_controller.dart';

/// Search screen — real results from the live source, with local recent
/// searches and live download progress.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _history = SearchHistoryStore();
  List<BzTrack> _results = [];
  List<String> _recentSearches = [];
  var _loading = false;
  var _searched = false;
  String? _error;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _history.load();
      if (!mounted) return;
      setState(() => _recentSearches = history);
    } catch (_) {
      // Search must remain usable when local history storage is unavailable.
    }
  }

  Future<void> _search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final generation = ++_searchGeneration;
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });

    // Search history is best-effort local UI state. A disk failure must not
    // prevent the actual catalogue search or masquerade as a provider outage.
    try {
      final history = await _history.add(normalized);
      if (mounted && generation == _searchGeneration) {
        setState(() => _recentSearches = history);
      }
    } catch (_) {
      // Continue with the music-source request even if persistence fails.
    }

    try {
      final op = await ref.read(youtubeSourceProvider).search(normalized);
      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        _loading = false;
        _results = op is ProviderOk<List<ProviderTrack>>
            ? op.value
                .map((track) => BzTrack(
                      id: track.breezzeTrackId,
                      title: track.title,
                      artist: track.artist,
                      artworkUrl: track.artworkUrl,
                      duration: track.duration,
                    ))
                .toList()
            : [];
        if (op is! ProviderOk<List<ProviderTrack>>) {
          _error = 'Search could not be completed. Try again in a moment.';
        }
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _loading = false;
        _results = [];
        _error = 'Could not reach the music source. Check your connection.';
      });
    }
  }

  Future<void> _removeHistory(String query) async {
    final history = await _history.remove(query);
    if (!mounted) return;
    setState(() => _recentSearches = history);
  }

  Future<void> _clearHistory() async {
    await _history.clear();
    if (!mounted) return;
    setState(() => _recentSearches = []);
  }

  void _reuseSearch(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _search(query);
  }

  void _download(BzTrack track) {
    ref.read(downloadProgressProvider.notifier).download(track);
  }

  void _play(BzTrack track) {
    final queue = [
      for (final item in _results)
        TrackInfo(
          id: item.id,
          title: item.title,
          artist: item.artist,
          artworkUrl: item.artworkUrl,
          duration: item.duration,
        )
    ];
    final index = _results.indexOf(track);
    if (queue.isEmpty) return;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search', style: theme.textTheme.displayMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Songs, artists and more',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchGeneration++;
                              _controller.clear();
                              setState(() {
                                _loading = false;
                                _searched = false;
                                _results = [];
                                _error = null;
                              });
                            },
                          ),
                    filled: true,
                    fillColor: theme.bzSurface1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BzRadius.input),
                      borderSide: BorderSide(color: theme.bzSeparator),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BzRadius.input),
                      borderSide: BorderSide(color: theme.bzSeparator),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? _buildRecentSearches(theme)
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Text(
                                  'No results for "${_controller.text.trim()}"',
                                  style: theme.textTheme.titleMedium,
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 8, 0, 220),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final track = _results[index];
                                  final value = progress[track.id];
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
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  BzBnoteMark(
                                                size: 48,
                                                color: theme.bzText2,
                                              ),
                                            ),
                                          )
                                        : BzBnoteMark(
                                            size: 48, color: theme.bzText2),
                                    title: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: value != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: value,
                                              minHeight: 3,
                                              backgroundColor:
                                                  theme.bzSeparator,
                                              color: theme.bzAccent,
                                            ),
                                          )
                                        : Text(
                                            track.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    trailing: value != null
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            tooltip: 'Download',
                                            icon: const Icon(
                                                Icons.download_outlined),
                                            onPressed: () => _download(track),
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

  Widget _buildRecentSearches(ThemeData theme) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BzBnoteMark(size: 64, color: theme.bzText2),
            const SizedBox(height: 16),
            Text('Find something to play',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Search songs and artists from the music source.',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 220),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent Searches',
                  style: theme.textTheme.titleLarge),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final query in _recentSearches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history, color: theme.bzText2),
            title: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _reuseSearch(query),
            trailing: IconButton(
              tooltip: 'Remove search',
              icon: const Icon(Icons.close),
              onPressed: () => _removeHistory(query),
            ),
          ),
      ],
    );
  }
}
