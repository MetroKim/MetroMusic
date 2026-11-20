import '../core/database/db_instance.dart';
import '../core/database/recently_played_dao.dart';

/// Recently-played store — now drift-backed (SQLite), same public API.
/// The 12-row cap and RecentEntry type are unchanged, so every screen
/// that uses RecentStore keeps working identically. The old JSON file
/// is only read once by the one-shot migration.
class RecentStore {
  static const cap = 12;

  final RecentlyPlayedDao _dao =
      RecentlyPlayedDao(breezzeDb);

  Future<List<RecentEntry>> load() async {
    final rows = await _dao.list();
    return [
      for (final r in rows)
        RecentEntry(
          id: r.id.value,
          title: r.title.value,
          artist: r.artist.value,
          artworkUrl: r.artworkUrl.value,
          durationMs: r.durationMs.value,
        )
    ];
  }

  Future<void> record(String id, String title, String artist,
      String? artworkUrl, Duration duration) {
    return _dao.record(
      id: id,
      title: title,
      artist: artist,
      artworkUrl: artworkUrl,
      durationMs: duration.inMilliseconds,
    );
  }
}

class RecentEntry {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final int durationMs;
  final int playedAtMs;

  const RecentEntry({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.durationMs = 0,
    this.playedAtMs = 0,
  });

  Duration get duration => Duration(milliseconds: durationMs);
}
