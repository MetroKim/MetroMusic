import 'package:breezze_api_client/breezze_api_client.dart';
import '../core/api/breezze_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session.dart';
import '../core/database/database_providers.dart';
import '../core/database/outbox_sync_service.dart';
import 'bootstrap.dart';

/// Live download progress, keyed by track id: 0.0–1.0, removed on finish.
final downloadProgressProvider =
    StateNotifierProvider<DownloadsController, Map<String, double>>(
        DownloadsController.new);

/// Downloads only short-lived URLs authorized by the Breezze backend.
/// Provider metadata/search adapters are never allowed to grant download
/// rights or expose a raw stream URL.
class DownloadsController extends StateNotifier<Map<String, double>> {
  DownloadsController(this.ref) : super({});

  final Ref ref;

  Future<void> download(BzTrack track) async {
    if (state.containsKey(track.id)) return;

    try {
      final auth = ref.read(authSessionProvider);
      if (auth is! AuthSignedIn) return;

      final api = ref.read(authSessionProvider.notifier).api;
      if (api.accessToken == null) return;

      final catalogId = await _resolveCatalogId(api, track);
      if (catalogId == null) return;

      final authorization = await api.authorizeDownload(
        trackId: catalogId,
        territory: ref.read(outboxTerritoryProvider),
      );
      if (authorization['allowed'] != true) {
        // ignore: avoid_print
        print('download_not_authorized: ${authorization['reason']}');
        return;
      }

      final downloadUrl = authorization['url'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) return;

      state = {...state, track.id: 0.0};
      final dir = await downloadsDirectory();
      final library = DownloadsLibrary(
        root: dir,
        lyrics: ref.read(lyricsProvider),
      );
      final ok = await library.download(
        track,
        downloadUrl: downloadUrl,
        onProgress: (progress) {
          if (mounted) state = {...state, track.id: progress};
        },
      );

      if (!ok) {
        // ignore: avoid_print
        print('download_failed: ${track.title}');
      }
    } catch (_) {
      // ignore: avoid_print
      print('download_failed: ${track.title}');
    } finally {
      if (mounted) {
        final next = Map<String, double>.of(state)..remove(track.id);
        state = next;
      }
    }
  }

  Future<String?> _resolveCatalogId(
    BreezzeApi api,
    BzTrack track,
  ) async {
    if (!track.id.startsWith('bz:')) return track.id;

    final mapDao = ref.read(catalogIdMapDaoProvider);
    final cached = await mapDao.lookup(track.id);
    if (cached != null) return cached;

    final resolved = await api.resolveCatalogTrack(
      externalId: track.id,
      source: 'youtube',
      title: track.title,
      artistName: track.artist,
      durationSec: track.duration.inSeconds.clamp(1, 86400).toInt(),
    );
    final catalogId = resolved['id'] as String?;
    if (catalogId == null || catalogId.isEmpty) return null;
    await mapDao.save(track.id, catalogId);
    return catalogId;
  }
}
