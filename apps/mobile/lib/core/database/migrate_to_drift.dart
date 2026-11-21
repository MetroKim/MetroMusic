import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'database_providers.dart';
import '../../app/bootstrap.dart' show FavoriteTrack;
import '../../app/recent_store.dart' show RecentEntry;

/// One-shot legacy migration: JSON files → SQLite (Drift).
/// Safe on every launch — insertOnConflictUpdate makes it idempotent.
/// A corrupt or missing legacy file never blocks startup.
Future<void> migrateJsonStoresToDrift(ProviderContainer container) async {
  try {
    final base = await getApplicationDocumentsDirectory();

    // --- favorites ---
    final favFile = File('${base.path}/breezze_favorites.json');
    if (await favFile.exists()) {
      final raw = jsonDecode(await favFile.readAsString());
      if (raw is List) {
        final favoritesDao = container.read(favoritesDaoProvider);
        for (final item in raw) {
          if (item is! Map) continue;
          final t = FavoriteTrack.fromJson(
              Map<String, Object?>.from(item));
          await favoritesDao.add(
            id: t.id,
            title: t.title,
            artist: t.artist,
            artworkUrl: t.artworkUrl,
            durationMs: t.durationMs,
          );
        }
      }
    }

    // --- recently played (import oldest-first so the cap trims the
    //     oldest, preserving the 12 newest as the JSON store had) ---
    final recentFile = File('${base.path}/breezze_recent.json');
    if (await recentFile.exists()) {
      final raw = jsonDecode(await recentFile.readAsString());
      if (raw is List) {
        final recentDao = container.read(recentlyPlayedDaoProvider);
        final entries = <RecentEntry>[];
        for (final item in raw) {
          if (item is! Map) continue;
          entries.add(RecentEntry(
            id: item['id'] as String,
            title: item['title'] as String? ?? '',
            artist: item['artist'] as String? ?? '',
            artworkUrl: item['artworkUrl'] as String?,
            durationMs: item['durationMs'] as int? ?? 0,
            playedAtMs: item['playedAtMs'] as int? ?? 0,
          ));
        }
        entries.sort((a, b) => a.playedAtMs.compareTo(b.playedAtMs));
        for (final e in entries) {
          await recentDao.record(
            id: e.id,
            title: e.title,
            artist: e.artist,
            artworkUrl: e.artworkUrl,
            durationMs: e.durationMs,
          );
        }
      }
    }
  } catch (_) {
    // Migration is best-effort. DB simply starts empty on failure.
  }
}
