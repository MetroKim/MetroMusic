import 'package:breezze_api_client/breezze_api_client.dart';
import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Automix (§9.7)', () {
    const mix = Automix();

    test('beat-matches close BPMs', () {
      final t = mix.plan(
        const TrackAnalysis(bpm: 120, energy: 0.5),
        const TrackAnalysis(bpm: 121, energy: 0.5),
      );
      expect(t.beatMatched, isTrue);
      expect(t.tempoFactor, inInclusiveRange(0.99, 1.01));
      expect(t.doubleTimeFold, isFalse);
    });

    test('folds half-time BPMs to match', () {
      final t = mix.plan(
        const TrackAnalysis(bpm: 120, energy: 0.3),
        const TrackAnalysis(bpm: 60, energy: 0.3),
      );
      expect(t.beatMatched, isTrue);
      expect(t.doubleTimeFold, isTrue);
    });

    test('no match when BPMs are far apart', () {
      final t = mix.plan(
        const TrackAnalysis(bpm: 90, energy: 0.2),
        const TrackAnalysis(bpm: 160, energy: 0.9),
      );
      expect(t.beatMatched, isFalse);
      expect(t.tempoFactor, 1.0);
    });

    test('transition length scales with energy', () {
      final low = mix.plan(
        const TrackAnalysis(bpm: 120, energy: 0.0),
        const TrackAnalysis(bpm: 120, energy: 0.0),
      );
      final high = mix.plan(
        const TrackAnalysis(bpm: 120, energy: 1.0),
        const TrackAnalysis(bpm: 120, energy: 1.0),
      );
      expect(high.transitionMs, greaterThan(low.transitionMs));
    });
  });

  group('SourceChain (§52.7)', () {
    test('primary source serves first', () async {
      final chain = SourceChain([
        _StubSource('primary', canPlay: true),
        _StubSource('fallback', canPlay: true),
      ]);
      final result = await chain.resolve('t1', _ctx);
      expect(result, isA<SourceChainOk>());
      expect((result as SourceChainOk).fromSourceId, 'primary');
    });

    test('falls back when primary cannot play', () async {
      final chain = SourceChain([
        _StubSource('primary', canPlay: false),
        _StubSource('fallback', canPlay: true),
      ]);
      final result = await chain.resolve('t1', _ctx);
      expect((result as SourceChainOk).fromSourceId, 'fallback');
    });

    test('unavailable when no source can serve', () async {
      final chain = SourceChain([_StubSource('a', canPlay: false)]);
      final result = await chain.resolve('t1', _ctx);
      expect(result, isA<SourceChainUnavailable>());
    });

    test('search deduplicates across sources', () async {
      final chain = SourceChain([
        _StubSource('primary', canPlay: true),
        _StubSource('fallback', canPlay: true, duplicateSearch: true),
      ]);
      final results = await chain.searchAll('query');
      expect(results.length, 1);
    });
  });
}

final _ctx = ProviderUserContext(
    userId: 'u1', territory: 'IN', subscriptionTier: 'premium');

class _StubSource implements ProviderAdapter {
  final String id;
  final bool canPlay;
  final bool duplicateSearch;

  _StubSource(this.id, {required this.canPlay, this.duplicateSearch = false});

  @override
  String get providerId => id;

  @override
  String get adapterVersion => '1.0.0';

  @override
  bool get supportsPlayback => canPlay;

  @override
  Future<ProviderOp<List<ProviderTrack>>> search(String query) async {
    return ProviderOk([
      ProviderTrack(
        breezzeTrackId: 'bz-1',
        providerTrackId: 'p-1',
        title: 'Nightcall',
        artist: 'Kavinsky',
        duration: const Duration(seconds: 254),
      )
    ]);
  }

  @override
  Future<ProviderOp<ProviderTrack>> getTrack(String providerTrackId) async {
    return ProviderUnsupported('not_implemented');
  }

  @override
  Future<ProviderOp<String>> resolvePlayback(
      String providerTrackId, ProviderUserContext userContext) async {
    if (!canPlay) return ProviderUnsupported('no_rights');
    return ProviderOk('https://cdn.example/audio.flac');
  }

  @override
  Future<ProviderOp<String>> getAttributionRequirements(
      String providerTrackId) async {
    return ProviderOk('Breezze');
  }
}
