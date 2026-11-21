import 'bz_track.dart';
import 'provider_adapter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

/// YouTube metadata/search adapter.
///
/// This adapter is intentionally not a playback or download authority.
/// YouTube metadata access does not grant Breezze rights to stream or cache
/// the underlying recording. Full playback and downloads must use URLs
/// authorized by Breezze's backend rights services.
class YoutubeSourceAdapter implements ProviderAdapter {
  final yt.YoutubeExplode _client = yt.YoutubeExplode();

  @override
  String get providerId => 'youtube_metadata';

  @override
  String get adapterVersion => '3.1.0';

  @override
  bool get supportsPlayback => false;

  static BzTrack _toTrack(yt.Video video) => BzTrack(
        id: 'bz:${video.id.value}',
        title: video.title,
        artist: video.author,
        artworkUrl: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
      );

  static ProviderTrack _toProviderTrack(BzTrack track) => ProviderTrack(
        breezzeTrackId: track.id,
        providerTrackId:
            track.id.startsWith('bz:') ? track.id.substring(3) : track.id,
        title: track.title,
        artist: track.artist,
        artworkUrl: track.artworkUrl,
        duration: track.duration,
      );

  @override
  Future<ProviderOp<List<ProviderTrack>>> search(String query) async {
    try {
      final videos = await (await _client.search(query)).take(20).toList();
      final tracks = videos.map(_toTrack).map(_toProviderTrack).toList();
      if (tracks.isEmpty) return ProviderError('empty_result');
      return ProviderOk(tracks);
    } catch (_) {
      return ProviderError('network_error');
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
    String providerTrackId,
    ProviderUserContext userContext,
  ) async =>
      ProviderUnsupported('BACKEND_RIGHTS_CHECK_REQUIRED');

  @override
  Future<ProviderOp<String>> getAttributionRequirements(
    String providerTrackId,
  ) async =>
      ProviderOk('YouTube metadata via Breezze search');

  void dispose() => _client.close();
}
