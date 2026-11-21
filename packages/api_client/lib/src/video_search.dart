import 'bz_track.dart';
import 'provider_adapter.dart';
import 'youtube_source_adapter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

/// Video search model — a music-video result from the live source.
/// Distinct from [ProviderTrack]: carries the video id for the
/// official embed player and a small thumbnail set.
class BzVideo {
  /// Video id, WITHOUT the 'bz:' prefix — used directly in the
  /// official embed URL.
  final String videoId;

  final String title;
  final String channel;
  final String? thumbnailUrl;
  final Duration duration;

  /// Direct official embed URL (the sanctioned playback surface):
  /// the provider's own player, no stream extraction.
  String get embedUrl =>
      'https://www.youtube.com/embed/$videoId?playsinline=1&app=breezze';

  const BzVideo({
    required this.videoId,
    required this.title,
    required this.channel,
    this.thumbnailUrl,
    this.duration = Duration.zero,
  });
}

/// Extension on the existing [ProviderAdapter] contract: video search.
///
/// Music-video discovery reuses the same keyless fetch engineering as
/// song search. Playback goes through the official embed player (the
/// sanctioned route) — this adapter never extracts video stream URLs.
extension VideoSearchX on YoutubeSourceAdapter {
  /// Searches music videos. youtube_explode's search defaults to the
  /// video filter (`TypeFilters.video`), so results are videos and the
  /// query is enriched with the "music video" intent.
  Future<ProviderOp<List<BzVideo>>> searchVideos(String query) async {
    try {
      final videos =
          await _client.search('$query music video').take(15).toList();
      final results = [
        for (final v in videos)
          BzVideo(
            videoId: v.id.value,
            title: v.title,
            channel: v.author,
            thumbnailUrl:
                v.thumbnails.isNotEmpty ? v.thumbnails.last.url : null,
            duration: v.duration,
          ),
      ];
      if (results.isEmpty) return ProviderError('empty_result');
      return ProviderOk(results);
    } catch (_) {
      return ProviderError('network_error');
    }
  }
}
