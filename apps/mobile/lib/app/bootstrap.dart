import 'dart:convert';
import 'dart:io';

import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/api/breezze_api.dart';
import '../core/auth/auth_session.dart';
import '../core/database/database_providers.dart';
import '../core/database/outbox_sync_service.dart';
import '../core/database/db_instance.dart';
import '../core/database/favorites_dao.dart';
import '../features/player/player_controller.dart';

/// Composition root for Breezze app services.
///
/// YouTube is used for metadata discovery only. Full playback and downloads
/// are resolved through backend rights checks and signed CDN URLs. Lyrics
/// lookup remains keyless through LRCLIB.

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

/// The app-wide metadata/search adapter; it is not a playback authority.
final youtubeSourceProvider =
    Provider<YoutubeSourceAdapter>((ref) => YoutubeSourceAdapter());

/// The lyrics provider.
final lyricsProvider =
    Provider<LyricsProvider>((ref) => LyricsProvider(HttpLyrics()));

/// Metadata search chain. No source in this chain grants playback rights.
final sourceChainProvider = Provider<SourceChain>((ref) => SourceChain([
      ref.watch(youtubeSourceProvider),
    ]));

/// The playback resolver. Catalog metadata is converged to a canonical
/// backend track ID, then full-stream playback is authorized by the backend.
/// The mobile client never turns a YouTube metadata result directly into a
/// playable stream URL.
class LiveResolver implements PlaybackResolver {
  final Ref _ref;

  LiveResolver(this._ref);

  @override
  Future<PlayableSource?> resolve(TrackInfo track) async {
    final auth = _ref.read(authSessionProvider);
    if (auth is! AuthSignedIn) return null;

    final api = _ref.read(authSessionProvider.notifier).api;
    if (api.accessToken == null) return null;

    try {
      final catalogId = await _resolveCatalogId(api, track);
      if (catalogId == null) return null;

      final result = await api.resolvePlayback(
        trackId: catalogId,
        territory: _ref.read(outboxTerritoryProvider),
      );
      final streamUrl = result['streamUrl'] as String?;
      final expiresAt = DateTime.tryParse(result['expiresAt'] as String? ?? '');
      if (streamUrl == null || expiresAt == null) return null;

      return PlayableSource(
        trackId: track.id,
        streamUrl: streamUrl,
        expiresAtUtc: expiresAt.toUtc(),
        codec: result['codec'] as String?,
      );
    } catch (_) {
      // Rights denials and backend/network failures are unavailable playback,
      // not permission to fall back to an unlicensed provider URL.
      return null;
    }
  }

  Future<String?> _resolveCatalogId(BreezzeApi api, TrackInfo track) async {
    if (!track.id.startsWith('bz:')) return track.id;

    final mapDao = _ref.read(catalogIdMapDaoProvider);
    final cached = await mapDao.lookup(track.id);
    if (cached != null) return cached;

    final title = track.title;
    final artist = track.artist;
    if (title == null || title.trim().isEmpty ||
        artist == null || artist.trim().isEmpty) {
      return null;
    }

    final resolved = await api.resolveCatalogTrack(
      externalId: track.id,
      source: 'youtube',
      title: title,
      artistName: artist,
      durationSec: track.duration.inSeconds.clamp(1, 86400).toInt(),
    );
    final catalogId = resolved['id'] as String?;
    if (catalogId == null || catalogId.isEmpty) return null;
    await mapDao.save(track.id, catalogId);
    return catalogId;
  }
}

/// Resolver override applied in main() via ProviderScope.
final liveResolverProvider =
    Provider<PlaybackResolver>((ref) => LiveResolver(ref));

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
