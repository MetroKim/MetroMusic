import 'dart:io';

import 'bz_track.dart';
import 'lyrics_provider.dart';

/// Downloads library — offline tracks with lyrics and cover art stored
/// alongside each track (§54.3).
///
/// Layout per track:
///   <downloadsDir>/<trackId>/audio.m4a
///   <downloadsDir>/<trackId>/cover.jpg
///   <downloadsDir>/<trackId>/lyrics.lrc
///   <downloadsDir>/<trackId>/meta.json
class DownloadsLibrary {
  final Directory root;
  final LyricsProvider lyrics;

  DownloadsLibrary({
    required this.root,
    required this.lyrics,
  });

  Directory _dirFor(String trackId) => Directory('${root.path}/$trackId');

  /// Downloads audio + cover art + lyrics for one track.
  ///
  /// [onProgress] receives 0.0–1.0 across the audio transfer (the
  /// dominant cost); lyrics and art are near-instant.
  Future<bool> download(
    BzTrack track, {
    required String downloadUrl,
    void Function(double progress)? onProgress,
  }) async {
    final dir = _dirFor(track.id);
    try {
      await dir.create(recursive: true);

      // 1. Fetch only the short-lived URL issued by the backend after its
      // download-rights decision. Never extract media directly from a
      // metadata/search provider in the client.
      final audioFile = File('${dir.path}/audio.m4a');
      if (!await audioFile.exists()) {
        final partialFile = File('${dir.path}/audio.part');
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(downloadUrl));
          final response = await request.close();
          if (response.statusCode != HttpStatus.ok) {
            throw HttpException(
              'authorized_download_${response.statusCode}',
              uri: Uri.parse(downloadUrl),
            );
          }

          final sink = partialFile.openWrite();
          var received = 0;
          try {
            await for (final chunk in response) {
              sink.add(chunk);
              received += chunk.length;
              if (response.contentLength > 0) {
                onProgress?.call(
                  (received / response.contentLength).clamp(0.0, 1.0),
                );
              }
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
          await partialFile.rename(audioFile.path);
        } catch (_) {
          if (await partialFile.exists()) {
            await partialFile.delete();
          }
          rethrow;
        } finally {
          client.close(force: true);
        }
      }
      onProgress?.call(1.0);

      // 2. Cover art
      if (track.artworkUrl != null) {
        final coverFile = File('${dir.path}/cover.jpg');
        if (!await coverFile.exists()) {
          final client = HttpClient();
          try {
            final request = await client.getUrl(Uri.parse(track.artworkUrl!));
            final response = await request.close();
            await response.pipe(coverFile.openWrite());
          } finally {
            client.close();
          }
        }
      }

      // 3. Lyrics (LRCLIB synced when available)
      final lyricsFile = File('${dir.path}/lyrics.lrc');
      final result = await lyrics.bestFor(track);
      if (result != null) {
        await lyricsFile.writeAsString(result.bestLrc);
      }

      // 4. Metadata
      final metaFile = File('${dir.path}/meta.json');
      await metaFile.writeAsString(
          '{"title":${_jsonEncode(track.title)},"artist":${_jsonEncode(track.artist)}}');

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Minimal JSON string escaping for the metadata file.
  String _jsonEncode(String value) {
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
    return '"$escaped"';
  }

  /// All downloaded tracks with their local assets resolved.
  Future<List<DownloadedTrack>> list() async {
    final tracks = <DownloadedTrack>[];
    if (!await root.exists()) return tracks;
    await for (final entry in root.list()) {
      if (entry is! Directory) continue;
      final metaFile = File('${entry.path}/meta.json');
      if (!await metaFile.exists()) continue;
      try {
        final raw = await metaFile.readAsString();
        final title = RegExp(r'"title"\s*:\s*"((?:[^"\\]|\\.)*)"')
            .firstMatch(raw)
            ?.group(1)
            ?.replaceAll('\\\\"', '"')
            .replaceAll('\\\\n', '\n')
            .replaceAll('\\\\', '\\');
        final artist = RegExp(r'"artist"\s*:\s*"((?:[^"\\]|\\.)*)"')
            .firstMatch(raw)
            ?.group(1)
            ?.replaceAll('\\\\"', '"')
            .replaceAll('\\\\n', '\n')
            .replaceAll('\\\\', '\\');
        tracks.add(DownloadedTrack(
          trackId: entry.uri.pathSegments.last,
          title: (title ?? 'Unknown').isNotEmpty ? title! : 'Unknown',
          artist: artist ?? 'Unknown',
          audioPath: '${entry.path}/audio.m4a',
          coverPath: await File('${entry.path}/cover.jpg').exists()
              ? '${entry.path}/cover.jpg'
              : null,
          lyricsPath: await File('${entry.path}/lyrics.lrc').exists()
              ? '${entry.path}/lyrics.lrc'
              : null,
        ));
      } catch (_) {
        continue;
      }
    }
    return tracks;
  }

  Future<void> remove(String trackId) async {
    final dir = _dirFor(trackId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// A downloaded track with its local file paths.
class DownloadedTrack {
  final String trackId;
  final String title;
  final String artist;
  final String audioPath;
  final String? coverPath;
  final String? lyricsPath;

  const DownloadedTrack({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.audioPath,
    this.coverPath,
    this.lyricsPath,
  });
}
