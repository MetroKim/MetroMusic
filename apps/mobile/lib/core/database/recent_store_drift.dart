import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/recent_store.dart' show RecentEntry;
import 'database_providers.dart';
import 'recently_played_dao.dart';

/// Drift-backed recently-played store — same public API as the JSON
/// RecentStore (load / record / RecentEntry), 12-row cap preserved.
class RecentStoreDrift {
  final RecentlyPlayedDao _dao;
  RecentStoreDrift(this._dao);

  Future<List<RecentEntry>> load() async {
    final rows = await _dao.list();
    return rows
        .map((r) => RecentEntry(
              id: r.id.value,
              title: r.title.value,
              artist: r.artist.value,
              artworkUrl: r.artworkUrl.value,
              durationMs: r.durationMs.value,
            ))
        .toList();
  }

  Future<void> record(
    String id,
    String title,
    String artist,
    String? artworkUrl,
    Duration duration,
  ) {
    return _dao.record(
      id: id,
      title: title,
      artist: artist,
      artworkUrl: artworkUrl,
      durationMs: duration.inMilliseconds,
    );
  }

  /// One-time legacy import: JSON → SQLite.
  Future<void> migrateFromJson(List<RecentEntry> legacy) async {
    for (final e in legacy) {
      await _dao.record(
        id: e.id,
        title: e.title,
        artist: e.artist,
        artworkUrl: e.artworkUrl,
        durationMs: e.durationMs,
      );
    }
  }
}

final recentStoreDriftProvider = Provider<RecentStoreDrift>(
  (ref) => RecentStoreDrift(ref.watch(recentlyPlayedDaoProvider)),
);
