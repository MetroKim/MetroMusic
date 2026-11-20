import 'dart:convert';
import 'dart:io';

import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/audio/just_audio_engine_adapter.dart';
import '../core/database/db_instance.dart';
import '../core/database/favorites_dao.dart';
import '../features/player/player_controller.dart';

/// Composition root — the real, working wiring at startup.
///
/// No user API key anywhere: search + playback run through
/// youtube_explode_dart (keyless), lyrics through LRCLIB (keyless).

/// package:http impl of the lyrics HTTP seam.
class HttpLyrics implements LyricsHttp {
  final http.Client _client = http.Client();

  @override
  Future<String> getText(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw HttpException('lyrics_${response.statusCode}');
    }
    return response.body;
  }
}

/// The real playback source provider — app-wide singleton.
final youtubeSourceProvider =
    Provider<YoutubeSourceAdapter>((ref) => YoutubeSourceAdapter());

/// The lyrics provider.
final lyricsProvider =
    Provider<LyricsProvider>((ref) => LyricsProvider(HttpLyrics()));

/// The source chain: youtube_explode primary.
final sourceChainProvider = Provider<SourceChain>((ref) => SourceChain([
      ref.watch(youtubeSourceProvider),
    ]));

/// The playback resolver: resolves through the live source.
class LiveResolver implements PlaybackResolver {
  final YoutubeSourceAdapter source;

  LiveResolver(this.source);

  @override
  Future<PlayableSource?> resolve(String trackId) async {
    final videoId =
        trackId.startsWith('bz:') ? trackId.substring(3) : trackId;
    final stream = await source.resolveStream(videoId);
    if (stream == null) return null;
    return PlayableSource(
      trackId: trackId,
      streamUrl: stream.streamUrl,
      expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 6)),
      codec: stream.codec,
    );
  }
}

/// Resolver override applied in main() via ProviderScope.
final liveResolverProvider = Provider<PlaybackResolver>(
    (ref) => LiveResolver(ref.watch(youtubeSourceProvider)));

/// Attach the native engine to the global player.
void attachPlaybackEngine(ProviderContainer container) {
  final player = container.read(playerControllerProvider.notifier);
  player.attachEngine(JustAudioEngineAdapter());
}

// ---------------------------------------------------------------------------
// Storage (path_provider): app-private, survives restarts
// ---------------------------------------------------------------------------

/// App-private downloads directory — the real per-track offline library.
Future<Directory> downloadsDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/downloads');
  await dir.create(recursive: true);
  return dir;
}

// ---------------------------------------------------------------------------
// Favorites — drift-backed store, JSON kept only as the legacy import
// source for the one-shot migration.
// ---------------------------------------------------------------------------

/// A favorited track with its display info.
class FavoriteTrack {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final int durationMs;

  const FavoriteTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.durationMs = 0,
  });

  TrackInfo toTrackInfo() => TrackInfo(
        id: id,
        title: title,
        artist: artist,
        artworkUrl: artworkUrl,
        duration: Duration(milliseconds: durationMs),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'durationMs': durationMs,
      };

  static FavoriteTrack fromJson(Map<String, Object?> json) => FavoriteTrack(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        artworkUrl: json['artworkUrl'] as String?,
        durationMs: json['durationMs'] as int? ?? 0,
      );
}

/// Legacy JSON favorites reader — used ONLY by the one-shot migration.
class LegacyFavoritesJson {
  static const _fileName = 'breezze_favorites.json';

  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/$_fileName');
  }

  Future<List<FavoriteTrack>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return [
        for (final item in raw)
          if (item is Map) FavoriteTrack.fromJson(item.cast<String, Object?>())
      ];
    } catch (_) {
      return [];
    }
  }
}

/// Favorites store — drift-backed (SQLite). Same public API as the
/// JSON version (load / toggle / isFavorite), so screens are unchanged.
class FavoritesStore {
  final FavoritesDao _dao = FavoritesDao(breezzeDb);

  Future<List<FavoriteTrack>> load() async {
    final rows = await _dao.list();
    return [
      for (final r in rows)
        FavoriteTrack(
          id: r.id.value,
          title: r.title.value,
          artist: r.artist.value,
          artworkUrl: r.artworkUrl.value,
          durationMs: r.durationMs.value,
        )
    ];
  }

  /// Returns true when the track was added, false when removed.
  Future<bool> toggle(FavoriteTrack track) async {
    if (await _dao.contains(track.id)) {
      await _dao.remove(track.id);
      return false;
    }
    await _dao.add(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artworkUrl: track.artworkUrl,
      durationMs: track.durationMs,
    );
    return true;
  }

  Future<bool> isFavorite(String id) => _dao.contains(id);
}

/// App-wide favorites store provider.
final favoritesStoreProvider =
    Provider<FavoritesStore>((ref) => FavoritesStore());
