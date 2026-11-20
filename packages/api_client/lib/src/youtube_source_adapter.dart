import 'bz_track.dart';
import 'provider_adapter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

/// Breezze real playback source — youtube_explode_dart 3.1.0.
///
/// The working fetch/search engine: a maintained Dart library (active,
/// keyless) that resolves YouTube stream URLs and search internally — the
/// same role BitChord's innerTube stack plays on Android. No user key
/// needed at any layer.
class YoutubeSourceAdapter implements ProviderAdapter {
  final yt.YoutubeExplode _client = yt.YoutubeExplode();

  @override
  String get providerId => 'bitchord';

  @override
  String get adapterVersion => '3.1.0';

  @override
  bool get supportsPlayback => true;

  // ---- helpers -----------------------------------------------------------

  static BzTrack _toTrack(yt.Video video) => BzTrack(
        id: 'bz:${video.id.value}',
        title: video.title,
        artist: video.author,
        artworkUrl:
            video.thumbnails.isNotEmpty ? video.thumbnails.last.url : null,
        duration: video.duration,
      );

  static ProviderTrack _toProviderTrack(BzTrack t) => ProviderTrack(
        breezzeTrackId: t.id,
        providerTrackId: t.id.startsWith('bz:') ? t.id.substring(3) : t.id,
        title: t.title,
        artist: t.artist,
        artworkUrl: t.artworkUrl,
        duration: t.duration,
      );

  static yt.AudioOnlyStreamInfo? _bestAudio(
      yt.StreamManifest manifest) {
    yt.AudioOnlyStreamInfo? best;
    for (final stream in manifest.audioOnly) {
      if (best == null || stream.bitrate > best.bitrate) {
        best = stream;
      }
    }
    return best;
  }

  // ---- API ---------------------------------------------------------------

  @override
  Future<ProviderOp<List<ProviderTrack>>> search(String query) async {
    try {
      final videos = await _client.search(query).take(20).toList();
      final tracks = videos.map(_toTrack).map(_toProviderTrack).toList();
      if (tracks.isEmpty) return ProviderError('empty_result');
      return ProviderOk(tracks);
    } catch (_) {
      return ProviderError('network_error');
    }
  }

  /// Resolves the highest-bitrate audio-only stream for playback.
  Future<ResolvedStream?> resolveStream(String videoId) async {
    try {
      final manifest =
          await _client.videos.streamsClient.getManifest(videoId);
      final best = _bestAudio(manifest);
      if (best == null) return null;
      return ResolvedStream(
        streamUrl: best.url.toString(),
        codec: best.codec.label,
        bitrate: best.bitrate,
        totalBytes: best.size.totalBytes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Raw audio bytes for offline downloads, with byte-accurate progress:
  /// [onProgress] receives 0.0–1.0 as chunks arrive.
  Stream<List<int>> audioBytes(
    String videoId, {
    void Function(double progress)? onProgress,
  }) async* {
    final manifest =
        await _client.videos.streamsClient.getManifest(videoId);
    final best = _bestAudio(manifest);
    if (best == null) {
      throw StateError('stream_unavailable');
    }
    final total = best.size.totalBytes;
    var received = 0;
    final byteStream = await _client.videos.streamsClient.getStream(best);
    await for (final chunk in byteStream) {
      received += chunk.length;
      onProgress?.call(total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0);
      yield chunk;
    }
  }

  @override
  Future<ProviderOp<ProviderTrack>> getTrack(String providerTrackId) async {
    try {
      final video = await _client.videos.get(providerTrackId);
      return ProviderOk(_toProviderTrack(_toTrack(video)));
    } catch (_) {
      return ProviderError('network_error');
    }
  }

  @override
  Future<ProviderOp<String>> resolvePlayback(
      String providerTrackId, ProviderUserContext userContext) async {
    final videoId = providerTrackId.startsWith('bz:')
        ? providerTrackId.substring(3)
        : providerTrackId;
    final stream = await resolveStream(videoId);
    if (stream == null) {
      return ProviderUnsupported('stream_unavailable');
    }
    return ProviderOk(stream.streamUrl);
  }

  @override
  Future<ProviderOp<String>> getAttributionRequirements(
      String providerTrackId) async {
    return ProviderOk('Music via Breezze source');
  }

  void dispose() => _client.close();
}

/// One resolved stream: URL + codec + bitrate + size.
class ResolvedStream {
  final String streamUrl;
  final String codec;
  final int bitrate;

  /// Total size in bytes, for download progress.
  final int totalBytes;

  const ResolvedStream({
    required this.streamUrl,
    required this.codec,
    required this.bitrate,
    required this.totalBytes,
  });
}
