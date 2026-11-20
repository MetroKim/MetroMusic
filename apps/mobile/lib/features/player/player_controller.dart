import 'dart:async';

import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/recent_store.dart';

/// Global PlayerController — spec §51.3, §53.1.
///
/// THE one application-wide playback authority. All screens dispatch
/// commands to it; a screen must never instantiate its own player for
/// catalog playback. Navigation never resets audio (§26.3).
class PlayerController extends Notifier<PlayerState> {
  late final PlaybackStateMachine _machine = PlaybackStateMachine(
    onTransition: (prev, next) {
      final s = state;
      state = s.copyWith(playbackState: next);
    },
  );

  late final QueueManager _queue = QueueManager(
    onQueueChanged: () {
      final s = state;
      state = s.copyWith(queueVersion: s.queueVersion + 1);
    },
  );

  late final ScrobbleBus _scrobbles = ScrobbleBus();

  /// Recently-played history, persisted by RecentStore.
  final RecentStore _recent = RecentStore();

  AudioEngineAdapter? _engine;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _engineStateSub;

  @override
  PlayerState build() => PlayerState.initial();

  QueueManager get queue => _queue;

  void attachEngine(AudioEngineAdapter engine) {
    _engine = engine;
    _positionSub?.cancel();
    _engineStateSub?.cancel();
    _positionSub = engine.positionStream.listen((pos) {
      final s = state;
      state = s.copyWith(position: pos, duration: engine.duration);
    });
    _engineStateSub = engine.engineStateStream.listen((st) {
      final s = state;
      state = s.copyWith(playbackState: st);
    });
  }

  void detachEngine() {
    _positionSub?.cancel();
    _engineStateSub?.cancel();
    _engine = null;
  }

  // ----------------------------------------------------------------
  // Commands (every command goes through the state machine, §53.2)
  // ----------------------------------------------------------------

  /// Plays one track, with optional full queue context.
  Future<void> playTrack({
    required String trackId,
    String? title,
    String? artist,
    String? artworkUrl,
    Duration duration = Duration.zero,
    List<TrackInfo> queue = const [],
    int startIndex = 0,
    String origin = 'manual',
    String sourceContext = 'Breezze',
  }) async {
    if (queue.isNotEmpty) {
      final entries = [
        for (var i = 0; i < queue.length; i++)
          QueueEntry(
            entryId: 'qe-$trackId-$i-${DateTime.now().microsecondsSinceEpoch}',
            trackId: queue[i].id,
            origin: origin,
            sourceContext: sourceContext,
            insertedAtMs: DateTime.now().millisecondsSinceEpoch,
            trackVersion: 'v1',
          ),
      ];
      _queue.replaceWith(entries, startIndex: startIndex);
    } else {
      final entry = QueueEntry(
        entryId: 'qe-${DateTime.now().microsecondsSinceEpoch}',
        trackId: trackId,
        origin: origin,
        sourceContext: sourceContext,
        insertedAtMs: DateTime.now().millisecondsSinceEpoch,
        trackVersion: 'v1',
      );
      _queue.replaceWith([entry]);
    }

    final info = queue.isEmpty
        ? TrackInfo(
            id: trackId,
            title: title,
            artist: artist,
            artworkUrl: artworkUrl,
            duration: duration,
          )
        : (startIndex < queue.length ? queue[startIndex] : queue.first);

    await _resolveAndPlay(info);
    _scrobbles.onPlay(info.id, DateTime.now().toUtc());
  }

  Future<void> togglePlayPause() async {
    if (state.playbackState == PlaybackState.playing) {
      _machine.dispatch(PausePressed());
      await _engine?.pause();
    } else {
      _machine.dispatch(PlayPressed());
      await _engine?.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    _machine.dispatch(SeekRequested(position));
    await _engine?.seek(position);
    _machine.dispatch(SeekCompleted());
  }

  Future<void> next() async {
    final entry = _queue.advance();
    if (entry == null) return;
    final info =
        _trackInfoFor(entry.trackId) ?? TrackInfo(id: entry.trackId);
    await _resolveAndPlay(info);
  }

  Future<void> previous() async {
    final entry = _queue.previous();
    if (entry == null) return;
    final info =
        _trackInfoFor(entry.trackId) ?? TrackInfo(id: entry.trackId);
    await _resolveAndPlay(info);
  }

  void toggleShuffle() => _queue.toggleShuffle();

  void cycleRepeat() => _queue.cycleRepeat();

  /// Track info remembered for the current queue, keyed by track id, so
  /// next/previous can show title/artist/artwork without re-fetching.
  final Map<String, TrackInfo> _trackInfos = {};

  TrackInfo? _trackInfoFor(String trackId) => _trackInfos[trackId];

  Future<void> _resolveAndPlay(TrackInfo info) async {
    _trackInfos[info.id] = info;
    state = state.copyWith(currentTrack: info);

    // Record to recently played (fire-and-forget; never block playback).
    if (info.title != null) {
      _recent
          .record(info.id, info.title!, info.artist ?? '', info.artworkUrl,
              info.duration)
          .catchError((_) {});
    }

    _machine.dispatch(StartRequested(info.id));
    final source =
        await ref.read(playbackResolverProvider).resolve(info.id);
    if (source == null) {
      _machine.dispatch(SourceResolutionFailed('NOT_AVAILABLE'));
      return;
    }
    _machine.dispatch(SourceResolved(info.id, source.streamUrl));
    await _engine?.prepare(source);
    _machine.dispatch(MediaReady());
    _machine.dispatch(PlayPressed());
    await _engine?.play();
  }
}

/// Display info for a track — what Now Playing renders.
class TrackInfo {
  final String id;
  final String? title;
  final String? artist;
  final String? artworkUrl;
  final Duration duration;

  const TrackInfo({
    required this.id,
    this.title,
    this.artist,
    this.artworkUrl,
    this.duration = Duration.zero,
  });
}

/// The backend playback resolver contract — platform-agnostic.
abstract interface class PlaybackResolver {
  Future<PlayableSource?> resolve(String trackId);
}

/// Provider for the resolver; overridden in bootstrap with the real
/// implementation.
final playbackResolverProvider = Provider<PlaybackResolver>((ref) {
  throw UnimplementedError('Overridden in bootstrap');
});

/// Immutable player state exposed to the UI.
class PlayerState {
  final PlaybackState playbackState;
  final Duration position;
  final Duration duration;
  final TrackInfo? currentTrack;

  /// Bumped on queue mutations; UI listens to this to rebuild queue views.
  final int queueVersion;

  const PlayerState({
    required this.playbackState,
    required this.position,
    required this.duration,
    required this.currentTrack,
    required this.queueVersion,
  });

  factory PlayerState.initial() => const PlayerState(
        playbackState: PlaybackState.idle,
        position: Duration.zero,
        duration: Duration.zero,
        currentTrack: null,
        queueVersion: 0,
      );

  PlayerState copyWith({
    PlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    TrackInfo? currentTrack,
    int? queueVersion,
  }) {
    return PlayerState(
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentTrack: currentTrack ?? this.currentTrack,
      queueVersion: queueVersion ?? this.queueVersion,
    );
  }
}

/// The single global provider — one instance app-wide (§53.1).
final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
