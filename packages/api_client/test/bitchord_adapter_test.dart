import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake homepage HTML with an embedded InnerTube config, as the real
/// music.youtube.com serves.
const fakeHomepage = '<html><body>'
    '"INNERTUBE_API_KEY":"AIza_fake_key_for_tests",'
    '"INNERTUBE_CLIENT_VERSION":"1.20261110.01.00"'
    '</body></html>';

/// Homepage carrying a key but no version string — exercises the
/// version fallback without tripping the missing-key error.
const noVersionHomepage = '<html><body>'
    '"INNERTUBE_API_KEY":"AIza_fake_key_for_tests"'
    '</body></html>';

void main() {
  group('InnertubeConfig scrape (BitChord model)', () {
    test('parses the public homepage config', () {
      final config = InnertubeConfig.parse(fakeHomepage);
      expect(config.apiKey, 'AIza_fake_key_for_tests');
      expect(config.clientVersion, '1.20261110.01.00');
    });

    test('falls back to default version when missing', () {
      final config = InnertubeConfig.parse(noVersionHomepage);
      expect(config.clientVersion, '1.20240101.01.00');
    });

    test('missing key throws config_scrape_failed', () {
      expect(() => InnertubeConfig.parse('<html>nothing</html>'),
          throwsStateError);
    });
  });

  group('BitChordAdapter (zero-config, no user key)', () {
    test('search works with no credentials, anonymous path', () async {
      final adapter = BitChordAdapter(http: _FakeBackend());

      final result = await adapter.search('kavinsky nightcall');

      expect(result, isA<ProviderOk<List<ProviderTrack>>>());
      final tracks = (result as ProviderOk<List<ProviderTrack>>).value;
      expect(tracks.first.title, 'Nightcall');
      expect(tracks.first.providerTrackId, 'abc123');
    });

    test('playback resolves when URL present, attaches poToken when supplied',
        () async {
      final withoutToken = BitChordAdapter(http: _FakeBackend());
      final result = await withoutToken.resolvePlayback(
        'abc123',
        ProviderUserContext(
            userId: 'u', territory: 'IN', subscriptionTier: 'premium'),
      );
      expect(result, isA<ProviderOk<String>>());

      final withToken = BitChordAdapter(
        http: _FakeBackend(),
        poTokenProvider: _FixedPoToken('MintsABotguardToken=='),
      );
      final withResult = await withToken.resolvePlayback(
        'abc123',
        ProviderUserContext(
            userId: 'u', territory: 'IN', subscriptionTier: 'premium'),
      );
      expect((withResult as ProviderOk<String>).value,
          contains('pot=MintsABotguardToken=='));
    });

    test('playability gate maps to honest unsupported', () async {
      final adapter = BitChordAdapter(http: _UnplayableBackend());
      final result = await adapter.resolvePlayback(
        'xyz',
        ProviderUserContext(
            userId: 'u', territory: 'IN', subscriptionTier: 'premium'),
      );
      expect(result, isA<ProviderUnsupported>());
      expect((result as ProviderUnsupported).reason, 'playability_UNPLAYABLE');
    });
  });
}

class _FakeBackend implements BackendHttp {
  @override
  Future<Object?> postJson(
    String url,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (url.contains('/search')) {
      return {
        'contents': [
          {
            'musicShelfRenderer': {
              'contents': [
                {
                  'musicResponsiveListItemRenderer': {
                    'playlistItemData': {'videoId': 'abc123'},
                    'flexColumns': [
                      {
                        'musicResponsiveListItemFlexColumnRenderer': {
                          'text': {
                            'runs': [
                              {'text': 'Nightcall'}
                            ]
                          }
                        }
                      },
                      {
                        'musicResponsiveListItemFlexColumnRenderer': {
                          'text': {
                            'runs': [
                              {'text': 'Kavinsky'}
                            ]
                          }
                        }
                      },
                    ],
                    'fixedColumns': [
                      {
                        'musicResponsiveListItemFixedColumnRenderer': {
                          'text': {
                            'runs': [
                              {'text': '4:14'}
                            ]
                          }
                        }
                      }
                    ],
                  }
                }
              ]
            }
          }
        ]
      };
    }
    if (url.contains('/player')) {
      return {
        'playabilityStatus': {'status': 'OK'},
        'streamingData': {
          'adaptiveFormats': [
            {
              'mimeType': 'audio/webm; codecs="opus"',
              'bitrate': 141100,
              'url': 'https://rr1.example.com/audio.webm',
            }
          ]
        },
      };
    }
    throw Exception('unexpected url');
  }

  @override
  Future<String> getText(String url) async => fakeHomepage;
}

class _UnplayableBackend implements BackendHttp {
  @override
  Future<Object?> postJson(
    String url,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (url.contains('/player')) {
      return {
        'playabilityStatus': {'status': 'UNPLAYABLE'},
      };
    }
    throw Exception('unexpected url');
  }

  @override
  Future<String> getText(String url) async => fakeHomepage;
}

class _FixedPoToken implements PoTokenProvider {
  final String value;
  _FixedPoToken(this.value);

  @override
  Future<String?> token() async => value;
}
