/// BitChord adapter — ported to BitChord's own zero-config model.
///
/// No user API key is required, exactly like the BitChord app: the client
/// config (InnerTube key + client version) is read off the public
/// music.youtube.com homepage at runtime, the same way BitChord's
/// capture scripts do it, and search uses the anonymous WEB_REMIX path
/// (no session cookie, per BitChord's postMusicAnonymous).
///
/// Full-track playback additionally needs the poToken BitChord mints
/// on-device (BotGuard WebView) — injected through [poTokenProvider].
library;

import 'bz_track.dart';
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

/// Supplies the poToken BitChord's BotGuard WebView mints on-device.
/// Null until the platform port is wired; playback then answers honestly.
abstract interface class PoTokenProvider {
  /// The visitor-bound poToken for streaming requests.
  Future<String?> token();
}

class BitChordAdapter implements ProviderAdapter {
  static const _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const _origin = 'https://music.youtube.com';
  static const _webRemixClientId = '67';

  final BackendHttp http;
  final PoTokenProvider? poTokenProvider;

  InnertubeConfig? _config;

  BitChordAdapter({required this.http, this.poTokenProvider});

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

  /// BitChord plays full tracks; so does Breezze once poToken is wired.
  @override
  bool get supportsPlayback => true;

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
    return _runsText(cols[index]);
  }

  static Duration _durationOf(Object? item) {
    final fixed = _walk(item, 'musicResponsiveListItemFixedColumnRenderer');
    if (fixed.isEmpty) return Duration.zero;
    final text = _runsText(fixed.first);
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
      String providerTrackId, ProviderUserContext userContext) async {
    final videoId =
        providerTrackId.startsWith('bz:') ? providerTrackId.substring(3) : providerTrackId;
    try {
      final config = await _ensureConfig();
      final data = await http.postJson(
        '$_baseUrl/player?prettyPrint=false&key=${config.apiKey}',
        {
          ..._context(config),
          'videoId': videoId,
          'contentCheckOk': true,
          'racyCheckOk': true,
        },
        headers: _headers(config.clientVersion),
      );

      // Playability gate, BitChord-style: read the status, not the HTTP code.
      final playability = _walk(data, 'playabilityStatus');
      if (playability.isNotEmpty && playability.first is Map) {
        final status = (playability.first as Map)['status'];
        if (status is String && status != 'OK') {
          return ProviderUnsupported('playability_$status');
        }
      }

      final formats = _walk(data, 'adaptiveFormats');
      String? bestUrl;
      var bestBitrate = -1;
      for (final format in formats) {
        if (format is! Map) continue;
        final mime = format['mimeType'];
        if (mime is! String || !mime.startsWith('audio/')) continue;
        if (format['signatureCipher'] != null) continue;
        final bitrate = (format['bitrate'] as num?)?.toInt() ?? 0;
        if (bitrate > bestBitrate && format['url'] is String) {
          bestBitrate = bitrate;
          bestUrl = format['url'] as String;
        }
      }

      if (bestUrl == null) {
        // These URLs are poToken-gated in the current era — the exact gap
        // BitChord's on-device BotGuard WebView closes. Honest result until
        // that module is ported.
        return ProviderUnsupported('po_token_required');
      }

      final poToken = await poTokenProvider?.token();
      if (poToken != null) {
        // BitChord appends the visitor poToken to the stream URL.
        return ProviderOk('$bestUrl&pot=$poToken');
      }
      return ProviderOk(bestUrl);
    } on StateError {
      return ProviderError('config_scrape_failed');
    } catch (_) {
      return ProviderError('network_error');
    }
  }

  @override
  Future<ProviderOp<String>> getAttributionRequirements(
      String providerTrackId) async {
    return ProviderOk('Music via BitChord source');
  }
}
