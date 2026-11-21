import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/api/breezze_api.dart';
import '../../core/auth/auth_session.dart';
import 'database_providers.dart';

/// Drains the sync outbox against the backend. Called after sign-in.
///
/// ID convergence: local ops carry EXTERNAL track ids (bz:<videoId>).
/// Before syncing, each op is mapped to the backend's canonical
/// catalog id via the local catalog_id_map cache; a miss calls
/// POST /catalog/resolve to create-or-fetch the canonical row, then
/// caches the mapping forever.
///
/// - favorite.add       → POST /library/favorites
/// - favorite.remove    → DELETE /library/favorites/:catalogId
/// - recent.play        → POST /home/plays
///
/// An op is deleted only after the backend accepted it. Any failure
/// stops the drain — offline actions are never lost.
class OutboxSyncService {
  final Ref _ref;

  OutboxSyncService(this._ref);

  bool _draining = false;

  Future<void> drainIfSignedIn() async {
    final auth = _ref.read(authSessionProvider);
    if (auth is! AuthSignedIn) return;
    if (_draining) return;
    _draining = true;
    try {
      final outbox = _ref.read(syncOutboxDaoProvider);
      final api = _ref.read(authSessionProvider.notifier).api;

      final ops = await outbox.pending();
      for (final op in ops) {
        // Map external id → catalog id (create on the backend if
        // unmapped). Unresolvable ops are discarded, not looped.
        final catalogId = await _resolveCatalogId(api, op.trackId);
        if (catalogId == null) {
          await outbox.discard(op.id);
          continue;
        }

        final ok = await _apply(api, op.op, catalogId);
        if (!ok) return; // stop on first failure, keep the rest queued
        await outbox.remove(op.id);
      }
    } finally {
      _draining = false;
    }
  }

  /// Returns the canonical catalog id for an external id, or null if
  /// the backend can't be reached (drain will retry next time).
  Future<String?> _resolveCatalogId(BreezzeApi api, String externalId) async {
    final mapDao = _ref.read(catalogIdMapDaoProvider);
    final cached = await mapDao.lookup(externalId);
    if (cached != null) return cached;

    // Resolve needs the track's display info to create the catalog
    // row. Pull it from the local favorites/recent tables.
    final info = await _localTrackInfo(externalId);
    if (info == null) {
      // Nothing local to describe the track — discard; the backend
      // would reject it anyway.
      return null;
    }

    try {
      final res = await http.post(
        Uri.parse('${api.baseUrl}/api/v1/catalog/resolve'),
        headers: {
          'Content-Type': 'application/json',
          if (api.accessToken != null)
            'Authorization': 'Bearer ${api.accessToken}',
        },
        body: jsonEncode({
          'externalId': externalId,
          'source': 'youtube',
          'title': info['title'],
          'artistName': info['artist'],
          'durationSec': (info['durationMs'] as int) ~/ 1000,
        }),
      );
      if (res.statusCode >= 400) return null;
      final data =
          jsonDecode(res.body) as Map<String, dynamic>;
      final map = data['data'] is Map ? data['data'] as Map<String, dynamic> : data;
      final catalogId = map['id'] as String?;
      if (catalogId == null) return null;
      await mapDao.save(externalId, catalogId);
      return catalogId;
    } catch (_) {
      return null;
    }
  }

  /// Track display info from whichever local table holds it.
  Future<Map<String, Object?>?> _localTrackInfo(String externalId) async {
    final db = _ref.read(breezzeDatabaseProvider);

    final favorite = await (db.select(db.favoriteTracks)
          ..where((t) => t.id.equals(externalId)))
        .getSingleOrNull();
    if (favorite != null) {
      return {
        'title': favorite.title,
        'artist': favorite.artist,
        'durationMs': favorite.durationMs,
      };
    }

    final recent = await (db.select(db.recentlyPlayed)
          ..where((t) => t.id.equals(externalId)))
        .getSingleOrNull();
    if (recent != null) {
      return {
        'title': recent.title,
        'artist': recent.artist,
        'durationMs': recent.durationMs,
      };
    }

    return null;
  }

  Future<bool> _apply(BreezzeApi api, String op, String catalogId) async {
    try {
      if (op == 'favorite.add' || op == 'recent.play') {
        final path = op == 'favorite.add'
            ? '/library/favorites'
            : '/home/plays';
        final res = await http.post(
          Uri.parse('${api.baseUrl}/api/v1$path'),
          headers: {
            'Content-Type': 'application/json',
            if (api.accessToken != null)
              'Authorization': 'Bearer ${api.accessToken}',
          },
          body: jsonEncode({'trackId': catalogId}),
        );
        return res.statusCode < 400;
      } else if (op == 'favorite.remove') {
        final res = await http.delete(
          Uri.parse('${api.baseUrl}/api/v1/library/favorites/$catalogId'),
          headers: {
            if (api.accessToken != null)
              'Authorization': 'Bearer ${api.accessToken}',
          },
        );
        return res.statusCode < 400;
      }
      // Unknown op type: drop it rather than loop forever.
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Territory for playback/plays endpoints; 'WW' default until
/// onboarding sets the user's country.
final outboxTerritoryProvider = StateProvider<String>((ref) => 'WW');

final outboxSyncProvider = Provider<OutboxSyncService>(
  (ref) => OutboxSyncService(ref),
);
