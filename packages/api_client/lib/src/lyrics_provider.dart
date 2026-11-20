/// Breezze lyrics provider — LRCLIB (lrclib.net).
///
/// Keyless, free, community API. Exact lookup keyed on track + artist +
/// duration (BitChord's rule: a duration of zero silently matches the
/// wrong edit), with fuzzy search fallback ranked by closest duration.
library;

import 'dart:convert';

import 'bz_track.dart';

class LyricsResult {
  final String plainLrc;
  final String? syncedLrc;
  final String trackName;
  final String artistName;

  /// Track duration in seconds, as LRCLIB states it. Used to rank fuzzy
  /// hits — the closest edit wins.
  final int durationSeconds;

  const LyricsResult({
    required this.plainLrc,
    this.syncedLrc,
    required this.trackName,
    required this.artistName,
    this.durationSeconds = 0,
  });

  /// The enhanced LRC to render — synced when available, plain otherwise.
  String get bestLrc => syncedLrc ?? plainLrc;
}

/// HTTP seam for lyrics — implemented over package:http in the app.
abstract interface class LyricsHttp {
  Future<String> getText(String url);
}

class LyricsProvider {
  static const _base = 'https://lrclib.net/api';

  final LyricsHttp http;

  LyricsProvider(this.http);

  /// Exact lookup: track + artist + album + duration.
  Future<LyricsResult?> getExact({
    required String trackName,
    required String artistName,
    String? albumName,
    required Duration duration,
  }) async {
    final params = Uri(queryParameters: {
      'track_name': trackName,
      'artist_name': artistName,
      if (albumName != null) 'album_name': albumName,
      'duration': duration.inSeconds.toString(),
    }).query;
    // A miss is a 404 — fall through to the caller's fuzzy path.
    return _parse(jsonDecode(await http.getText('$_base/get?$params')));
  }

  /// Fuzzy search when the album or exact duration is unknown.
  Future<List<LyricsResult>> search(BzTrack track) async {
    final params = Uri(queryParameters: {
      'q': '${track.title} ${track.artist}',
    }).query;
    final raw = await http.getText('$_base/search?$params');
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    final results = <LyricsResult>[];
    for (final item in list) {
      final parsed = _parse(item);
      if (parsed != null) results.add(parsed);
      if (results.length >= 5) break; // bounded
    }
    return results;
  }

  /// Best-effort: exact first, then fuzzy ranked by closest duration.
  /// A 404 from the exact lookup is a normal miss, not an error.
  Future<LyricsResult?> bestFor(BzTrack track, {String? albumName}) async {
    if (track.duration > Duration.zero) {
      try {
        final exact = await getExact(
          trackName: track.title,
          artistName: track.artist,
          albumName: albumName,
          duration: track.duration,
        );
        if (exact != null) return exact;
      } catch (_) {
        // fall through to fuzzy
      }
    }
    final fuzzy = await search(track);
    if (fuzzy.isEmpty) return null;
    LyricsResult best = fuzzy.first;
    var bestDelta = (track.duration.inSeconds - best.durationSeconds).abs();
    for (final result in fuzzy) {
      final delta = (track.duration.inSeconds - result.durationSeconds).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = result;
      }
    }
    return best;
  }

  LyricsResult? _parse(Object? item) {
    if (item is! Map) return null;
    final plain = item['plainLyrics'];
    final synced = item['syncedLyrics'];
    if (plain is! String && synced is! String) return null;
    final duration = item['duration'];
    final name = item['trackName'];
    final artist = item['artistName'];
    return LyricsResult(
      plainLrc: plain is String ? plain : '',
      syncedLrc: synced is String ? synced : null,
      trackName: name is String ? name : '',
      artistName: artist is String ? artist : '',
      durationSeconds: duration is num ? duration.toInt() : 0,
    );
  }
}
