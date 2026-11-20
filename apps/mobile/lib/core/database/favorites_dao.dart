import 'package:drift/drift.dart';

import 'breezze_database.dart';

/// Favorites repository over Drift. Every mutation also records a
/// pending op in the sync outbox so the backend can be reconciled
/// later without losing offline actions.
class FavoritesDao {
  final BreezzeDatabase _db;
  FavoritesDao(this._db);

  Future<List<FavoriteTracksCompanion>> list() async {
    final rows = await (_db.select(_db.favoriteTracks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows
        .map((r) => FavoriteTracksCompanion.insert(
              id: r.id,
              title: r.title,
              artist: r.artist,
              artworkUrl: Value(r.artworkUrl),
              durationMs: Value(r.durationMs),
            ))
        .toList();
  }

  Future<void> add({
    required String id,
    required String title,
    required String artist,
    String? artworkUrl,
    int durationMs = 0,
  }) async {
    await _db.into(_db.favoriteTracks).insertOnConflictUpdate(
          FavoriteTracksCompanion.insert(
            id: id,
            title: title,
            artist: artist,
            artworkUrl: Value(artworkUrl),
            durationMs: Value(durationMs),
          ),
        );
    await _db.into(_db.syncOutbox).insert(
          SyncOutboxCompanion.insert(op: 'favorite.add', trackId: id),
        );
  }

  Future<void> remove(String id) async {
    await (_db.delete(_db.favoriteTracks)..where((t) => t.id.equals(id)))
        .go();
    await _db.into(_db.syncOutbox).insert(
          SyncOutboxCompanion.insert(op: 'favorite.remove', trackId: id),
        );
  }

  Future<bool> contains(String id) async {
    final row = await (_db.select(_db.favoriteTracks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }
}
