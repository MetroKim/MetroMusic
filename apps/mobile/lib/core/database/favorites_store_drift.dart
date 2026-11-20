import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart' show FavoriteTrack;
import 'database_providers.dart';
import 'favorites_dao.dart';

/// Drift-backed favorites store — same public API as the JSON
/// FavoritesStore in bootstrap.dart (load / save / toggle /
/// isFavorite / FavoriteTrack), so no screen changes. JSON is legacy:
/// call migrateFromJson() once at startup, then the DB is the truth.
class FavoritesStoreDrift {
  final FavoritesDao _dao;
  FavoritesStoreDrift(this._dao);

  Future<List<FavoriteTrack>> load() async {
    final rows = await _dao.list();
    return rows
        .map((r) => FavoriteTrack(
              id: r.id.value,
              title: r.title.value,
              artist: r.artist.value,
              artworkUrl: r.artworkUrl.value,
              durationMs: r.durationMs.value,
            ))
        .toList();
  }

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

  /// One-time legacy import: JSON file → SQLite. Safe to call on
  /// every startup — already-imported rows are updated, not duplicated.
  Future<void> migrateFromJson(List<FavoriteTrack> legacy) async {
    for (final t in legacy) {
      await _dao.add(
        id: t.id,
        title: t.title,
        artist: t.artist,
        artworkUrl: t.artworkUrl,
        durationMs: t.durationMs,
      );
    }
  }
}

final favoritesStoreDriftProvider = Provider<FavoritesStoreDrift>(
  (ref) => FavoritesStoreDrift(ref.watch(favoritesDaoProvider)),
);
