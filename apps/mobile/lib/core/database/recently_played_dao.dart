import 'package:drift/drift.dart';

import 'breezze_database.dart';

/// Recently played repository over Drift — capped at 12 rows,
/// newest first, matching the old RecentStore behavior exactly.
class RecentlyPlayedDao {
  final BreezzeDatabase _db;
  RecentlyPlayedDao(this._db);

  static const _cap = 12;

  Future<List<RecentlyPlayedCompanion>> list() async {
    final rows = await (_db.select(_db.recentlyPlayed)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt)]))
        .get();
    return rows
        .map((r) => RecentlyPlayedCompanion.insert(
              id: r.id,
              title: r.title,
              artist: r.artist,
              artworkUrl: Value(r.artworkUrl),
              durationMs: Value(r.durationMs),
            ))
        .toList();
  }

  Future<void> record({
    required String id,
    required String title,
    required String artist,
    String? artworkUrl,
    int durationMs = 0,
  }) async {
    await _db.into(_db.recentlyPlayed).insertOnConflictUpdate(
          RecentlyPlayedCompanion.insert(
            id: id,
            title: title,
            artist: artist,
            artworkUrl: Value(artworkUrl),
            durationMs: Value(durationMs),
            playedAt: Value(DateTime.now()),
          ),
        );
    await _trim();

    await _db.into(_db.syncOutbox).insert(
          SyncOutboxCompanion.insert(op: 'recent.play', trackId: id),
        );
  }

  Future<void> _trim() async {
    final rows = await (_db.select(_db.recentlyPlayed)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt)]))
        .get();
    if (rows.length <= _cap) return;
    final toDelete = rows.skip(_cap).map((r) => r.id).toList();
    await (_db.delete(_db.recentlyPlayed)
          ..where((t) => t.id.isIn(toDelete)))
        .go();
  }
}
