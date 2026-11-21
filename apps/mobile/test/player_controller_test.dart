import 'dart:async';

import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breezze/features/player/player_controller.dart';

class _ControlledResolver implements PlaybackResolver {
  final Map<String, Completer<PlayableSource?>> pending = {};

  @override
  Future<PlayableSource?> resolve(TrackInfo track) {
    final completer = Completer<PlayableSource?>();
    pending[track.id] = completer;
    return completer.future;
  }

  void complete(String trackId) {
    pending[trackId]!.complete(PlayableSource(
      trackId: trackId,
      streamUrl: 'https://example.invalid/$trackId',
      expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
    ));
  }
}

class _FakeEngine implements AudioEngineAdapter {
  final StreamController<Duration> positions =
      StreamController<Duration>.broadcast();
  final StreamController<PlaybackState> states =
      StreamController<PlaybackState>.broadcast();
  final List<String> prepared = [];
  int playCount = 0;
  bool failPrepare = false;
  bool failPlay = false;
  Completer<void>? firstPrepare;

  @override
  Future<void> prepare(PlayableSource source) async {
    prepared.add(source.trackId);
    if (failPrepare) throw StateError('prepare failed');
    if (prepared.length == 1 && firstPrepare != null) {
      await firstPrepare!.future;
    }
  }

  @override
  Future<void> play() async {
    if (failPlay) throw StateError('play failed');
    playCount++;
    states.add(PlaybackState.playing);
  }

  @override
  Future<void> pause() async {
    states.add(PlaybackState.paused);
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => const Duration(minutes: 3);

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double rate) async {}

  @override
  Stream<Duration> get positionStream => positions.stream;

  @override
  Stream<PlaybackState> get engineStateStream => states.stream;

  Future<void> dispose() async {
    await positions.close();
    await states.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _ControlledResolver resolver;
  late _FakeEngine engine;

  setUp(() {
    resolver = _ControlledResolver();
    engine = _FakeEngine();
    container = ProviderContainer(overrides: [
      playbackResolverProvider.overrideWithValue(resolver),
    ]);
    container.read(playerControllerProvider.notifier).attachEngine(engine);
  });

  tearDown(() async {
    container.dispose();
    await engine.dispose();
  });

  test('late resolver response cannot replace the latest selected track',
      () async {
    final player = container.read(playerControllerProvider.notifier);

    final first = player.playTrack(trackId: 'track-a');
    final second = player.playTrack(trackId: 'track-b');

    resolver.complete('track-b');
    await second;
    resolver.complete('track-a');
    await first;

    expect(engine.prepared, ['track-b']);
    expect(engine.playCount, 1);
    expect(container.read(playerControllerProvider).currentTrack?.id,
        'track-b');
    expect(container.read(playerControllerProvider).playbackState,
        PlaybackState.playing);
  });

  test('an older prepare cannot overwrite a newer track', () async {
    final player = container.read(playerControllerProvider.notifier);
    engine.firstPrepare = Completer<void>();

    final first = player.playTrack(trackId: 'track-a');
    resolver.complete('track-a');
    await Future<void>.delayed(Duration.zero);

    final second = player.playTrack(trackId: 'track-b');
    resolver.complete('track-b');
    await Future<void>.delayed(Duration.zero);

    engine.firstPrepare!.complete();
    await Future.wait([first, second]);

    expect(engine.prepared, ['track-a', 'track-b']);
    expect(engine.playCount, 1);
    expect(container.read(playerControllerProvider).currentTrack?.id,
        'track-b');
  });

  test('resolver failure leaves the controller in failed state', () async {
    final player = container.read(playerControllerProvider.notifier);
    final request = player.playTrack(trackId: 'missing');

    resolver.pending['missing']!.complete(null);
    await request;

    expect(container.read(playerControllerProvider).playbackState,
        PlaybackState.failed);
    expect(engine.prepared, isEmpty);
  });

  test('stop invalidates an in-flight resolver and clears the player', () async {
    final player = container.read(playerControllerProvider.notifier);
    final request = player.playTrack(trackId: 'track-a');

    await player.stop();
    resolver.complete('track-a');
    await request;

    final state = container.read(playerControllerProvider);
    expect(state.playbackState, PlaybackState.idle);
    expect(state.currentTrack, isNull);
    expect(engine.prepared, isEmpty);
  });

  test('engine prepare failure is surfaced as failed playback', () async {
    engine.failPrepare = true;
    final player = container.read(playerControllerProvider.notifier);
    final request = player.playTrack(trackId: 'track-a');

    resolver.complete('track-a');
    await request;

    expect(container.read(playerControllerProvider).playbackState,
        PlaybackState.failed);
    expect(engine.playCount, 0);
  });

  test('engine play failure is surfaced after play is requested', () async {
    engine.failPlay = true;
    final player = container.read(playerControllerProvider.notifier);
    final request = player.playTrack(trackId: 'track-a');

    resolver.complete('track-a');
    await request;
    await Future<void>.delayed(Duration.zero);

    expect(container.read(playerControllerProvider).playbackState,
        PlaybackState.failed);
  });

}
