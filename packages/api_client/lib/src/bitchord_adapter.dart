/// BitChord adapter — ported to BitChord's own zero-config model.
///
/// No user API key is required, exactly like the BitChord app: the client
/// config (InnerTube key + client version) is read off the public
/// music.youtube.com homepage at runtime, the same way BitChord's
/// capture scripts do it, and search uses the anonymous WEB_REMIX path
/// (no session cookie, per BitChord's postMusicAnonymous).
///
/// This adapter is metadata/search only. BotGuard tokens or extracted stream
/// URLs do not grant Breezze playback rights; full playback must pass the
/// backend's catalog and rights authorization flow.
library;

import 'provider_adapter.dart';

/// Minimal HTTP seam — implemented in the app with package:http.
abstract interface class BackendHttp {
  Future<Object?> postJson(
    String url,
    Map<String, Object?> body, {
    Map<String, String> headers,
  });

  /// Plain GET returning the page text — used for the config scrape.
  Future<String> getText(String url);
}

/// Runtime client configuration scraped off the public homepage.
class InnertubeConfig {
  final String apiKey;
  final String clientVersion;

  const InnertubeConfig(this.apiKey, this.clientVersion);

  /// BitChord's approach: the homepage embeds both the current InnerTube
  /// key and the WEB_REMIX client version; regex them out.
  static InnertubeConfig parse(String html) {
    final key =
        RegExp(r'"INNERTUBE_API_KEY":"([^"]+)"').firstMatch(html)?.group(1);
    final version = RegExp(r'"INNERTUBE_CLIENT_VERSION":"([^"]+)"')
            .firstMatch(html)
            ?.group(1) ??
        '1.20240101.01.00';
    if (key == null) throw StateError('config_scrape_failed');
    return InnertubeConfig(key, version);
  }

  static Future<InnertubeConfig> fetch(BackendHttp http) =>
      http.getText('https://music.youtube.com/').then(parse);
}


class BitChordAdapter implements ProviderAdapter {
  static const _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const _origin = 'https://music.youtube.com';
  static const _webRemixClientId = '67';

  final BackendHttp http;

  InnertubeConfig? _config;

  BitChordAdapter({required this.http});

  Future<InnertubeConfig> _ensureConfig() async =>
      _config ??= await InnertubeConfig.fetch(http);

  Map<String, Object?> _context(InnertubeConfig config) => {
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': config.clientVersion,
            'hl': 'en',
            'gl': 'US',
          },
          'user': {'lockedSafetyMode': false},
          'request': {'useSsl': true},
        },
      };

  Map<String, String> _headers(String version) => {
        'X-Origin': _origin,
        'Origin': _origin,
        'Referer': '$_origin/',
        'X-YouTube-Client-Name': _webRemixClientId,
        'X-YouTube-Client-Version': version,
      };

  @override
  String get providerId => 'bitchord';

  @override
  String get adapterVersion => '2.0.0';

  /// Search metadata only. Playback must be authorized by Breezze's backend.
  @override
  bool get supportsPlayback => false;

  // ---- Parsing helpers (same shapes as before) --------------------------

  static List<Object?> _walk(Object? node, String key) {
    final out = <Object?>[];
    void visit(Object? n) {
      if (n is Map) {
        n.forEach((k, v) {
          if (k == key) out.add(v);
          visit(v);
        });
      } else if (n is List) {
        for (final item in n) {
          visit(item);
        }
      }
    }

    visit(node);
    return out;
  }

  static String? _runsText(Object? node) {
    if (node is! Map) return null;
    final runs = node['runs'];
    if (runs is! List) return null;
    final texts = <String>[];
    for (final run in runs) {
      if (run is Map && run['text'] is String) texts.add(run['text'] as String);
    }
    return texts.isEmpty ? null : texts.join('');
  }

  static String? _flexColumnText(Object? item, int index) {
    final cols = _walk(item, 'musicResponsiveListItemFlexColumnRenderer');
    if (index >= cols.length) return null;
    final renderer = cols[index];
    if (renderer is! Map) return null;
    return _runsText(renderer['text']);
  }

  static Duration _durationOf(Object? item) {
    final fixed = _walk(item, 'musicResponsiveListItemFixedColumnRenderer');
    if (fixed.isEmpty) return Duration.zero;
    final renderer = fixed.first;
    if (renderer is! Map) return Duration.zero;
    final text = _runsText(renderer['text']);
    if (text == null) return Duration.zero;
    final parts = text.split(':');
    try {
      if (parts.length == 2) {
        return Duration(seconds: int.parse(parts[0]) * 60 + int.parse(parts[1]));
      }
      if (parts.length == 3) {
        return Duration(
            seconds: int.parse(parts[0]) * 3600 +
                int.parse(parts[1]) * 60 +
                int.parse(parts[2]));
      }
    } catch (_) {
      return Duration.zero;
    }
    return Duration.zero;
  }

  static String? _videoIdOf(Object? item) {
    for (final data in _walk(item, 'playlistItemData')) {
      if (data is Map && data['videoId'] is String) {
        return data['videoId'] as String;
      }
    }
    return null;
  }

  static ProviderTrack? _toTrack(Object? item) {
    if (item is! Map) return null;
    final videoId = _videoIdOf(item);
    final title = _flexColumnText(item, 0);
    if (videoId == null || title == null) return null;
    return ProviderTrack(
      breezzeTrackId: 'bz:$videoId',
      providerTrackId: videoId,
      title: title,
      artist: _flexColumnText(item, 1) ?? 'Unknown artist',
      duration: _durationOf(item),
    );
  }

  // ---- API ---------------------------------------------------------------

  @override
  Future<ProviderOp<List<ProviderTrack>>> search(String query) async {
    try {
      final config = await _ensureConfig();
      // Anonymous path, per BitChord's postMusicAnonymous: no cookie, no
      // account context — search works with zero user credentials.
      final data = await http.postJson(
        '$_baseUrl/search?prettyPrint=false&key=${config.apiKey}',
        {..._context(config), 'query': query},
        headers: _headers(config.clientVersion),
      );
      final items = _walk(data, 'musicResponsiveListItemRenderer');
      final tracks = <ProviderTrack>[];
      for (final item in items) {
        final track = _toTrack(item);
        if (track != null) tracks.add(track);
      }
      if (tracks.isEmpty) return ProviderError('empty_result');
      return ProviderOk(tracks);
    } on StateError {
      return ProviderError('config_scrape_failed');
    } catch (_) {
      return ProviderError('network_error');
    }
  }

  @override
  Future<ProviderOp<ProviderTrack>> getTrack(String providerTrackId) async {
    return ProviderUnsupported('use_search');
  }

  @override
  Future<ProviderOp<String>> resolvePlayback(
    String providerTrackId,
    ProviderUserContext userContext,
  ) async =>
      ProviderUnsupported('BACKEND_RIGHTS_CHECK_REQUIRED');

  @override
  Future<ProviderOp<String>> getAttributionRequirements(
      String providerTrackId) async {
    return ProviderOk('YouTube Music metadata via Breezze search');
  }
}
