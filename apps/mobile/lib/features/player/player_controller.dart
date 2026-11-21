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
      state = state.copyWith(playbackState: next);
    },
  );

  late final QueueManager _queue = QueueManager(
    onQueueChanged: () {
      state = state.copyWith(queueVersion: state.queueVersion + 1);
    },
  );

  late final ScrobbleBus _scrobbles = ScrobbleBus();
  final RecentStore _recent = RecentStore();

  AudioEngineAdapter? _engine;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _engineStateSub;
  int _requestGeneration = 0;
  Future<void> _engineOperations = Future<void>.value();

  /// Track info remembered for the current queue, keyed by track id.
  final Map<String, TrackInfo> _trackInfos = {};

  @override
  PlayerState build() {
    ref.onDispose(() {
      _requestGeneration++;
      _positionSub?.cancel();
      _engineStateSub?.cancel();
      _engine = null;
    });
    return PlayerState.initial();
  }

  QueueManager get queue => _queue;

  void attachEngine(AudioEngineAdapter engine) {
    _requestGeneration++;
    _positionSub?.cancel();
    _engineStateSub?.cancel();
    _engine = engine;

    _positionSub = engine.positionStream.listen((pos) {
      if (!identical(_engine, engine)) return;
      state = state.copyWith(position: pos, duration: engine.duration);
    });
    _engineStateSub = engine.engineStateStream.listen((engineState) {
      if (!identical(_engine, engine)) return;

      // Ignore events emitted by the previous media item while the new
      // source is being resolved/prepared.
      if (state.playbackState == PlaybackState.idle ||
          state.playbackState == PlaybackState.resolving ||
          state.playbackState == PlaybackState.loading ||
          state.playbackState == PlaybackState.transitioning) {
        return;
      }
      state = state.copyWith(playbackState: engineState);
    });
  }

  void detachEngine() {
    _requestGeneration++;
    _positionSub?.cancel();
    _engineStateSub?.cancel();
    _positionSub = null;
    _engineStateSub = null;
    _engine = null;
  }

  // ----------------------------------------------------------------
  // Commands
  // ----------------------------------------------------------------

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
      for (final item in queue) {
        _trackInfos[item.id] = item;
      }
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
        : queue[startIndex.clamp(0, queue.length - 1)];

    await _resolveAndPlay(info);
  }

  /// Stops playback and clears the current queue. Used on explicit user stop
  /// and account sign-out so one user's media cannot continue into another
  /// account session.
  Future<void> stop() async {
    final requestId = ++_requestGeneration;
    final engine = _engine;
    _queue.clear(keepCurrent: false);
    _trackInfos.clear();
    _machine.dispatch(StopRequested(requestId: requestId));
    state = state.copyWith(
      clearCurrentTrack: true,
      position: Duration.zero,
      duration: Duration.zero,
    );
    if (engine == null) return;
    try {
      await _serializeEngineOperation(() => engine.stop());
    } catch (_) {
      // The logical player is already idle; native stop is best-effort.
    }
  }

  Future<void> pause() async {
    final engine = _engine;
    if (engine == null || state.playbackState != PlaybackState.playing) return;
    _machine.dispatch(PausePressed());
    try {
      await _serializeEngineOperation(() => engine.pause());
    } catch (_) {
      _machine.dispatch(SourceResolutionFailed('PAUSE_FAILED', requestId: _machine.activeRequestId));
    }
  }

  Future<void> resume() async {
    final engine = _engine;
    if (engine == null || state.playbackState != PlaybackState.paused) return;
    _machine.dispatch(PlayPressed());
    try {
      await _serializeEngineOperation(() async {
        unawaited(engine.play().catchError((Object error, StackTrace stackTrace) {
          _machine.dispatch(SourceResolutionFailed('RESUME_FAILED', requestId: _machine.activeRequestId));
        }));
      });
    } catch (_) {
      _machine.dispatch(SourceResolutionFailed('RESUME_FAILED', requestId: _machine.activeRequestId));
    }
  }

  Future<void> togglePlayPause() async {
    if (state.playbackState == PlaybackState.playing) {
      await pause();
    } else if (state.playbackState == PlaybackState.paused) {
      await resume();
    }
  }

  Future<void> seekTo(Duration position) async {
    final engine = _engine;
    if (engine == null || state.playbackState != PlaybackState.playing) {
      return;
    }
    _machine.dispatch(SeekRequested(position));
    await _serializeEngineOperation(() => engine.seek(position));
    _machine.dispatch(SeekCompleted());
  }

  Future<void> next() async {
    final entry = _queue.advance();
    if (entry == null) return;
    final info = _trackInfoFor(entry.trackId) ?? TrackInfo(id: entry.trackId);
    await _resolveAndPlay(info);
  }

  Future<void> previous() async {
    final entry = _queue.previous();
    if (entry == null) return;
    final info = _trackInfoFor(entry.trackId) ?? TrackInfo(id: entry.trackId);
    await _resolveAndPlay(info);
  }

  void toggleShuffle() => _queue.toggleShuffle();
  void cycleRepeat() => _queue.cycleRepeat();

  TrackInfo? _trackInfoFor(String trackId) => _trackInfos[trackId];

  bool _isCurrentRequest(int requestId) =>
      requestId == _requestGeneration && _engine != null;

  /// Serializes native engine mutations. Resolution remains concurrent, but
  /// prepare/play operations execute in order so an older prepare cannot
  /// finish after and overwrite a newer selected track.
  Future<void> _serializeEngineOperation(
      Future<void> Function() operation) {
    final result = _engineOperations.then((_) => operation());
    _engineOperations = result.catchError((_) {});
    return result;
  }

  Future<void> _resolveAndPlay(TrackInfo info) async {
    final requestId = ++_requestGeneration;
    _trackInfos[info.id] = info;
    state = state.copyWith(
      currentTrack: info,
      position: Duration.zero,
      duration: info.duration,
    );
    _machine.dispatch(StartRequested(info.id, requestId: requestId));

    try {
      final source =
          await ref.read(playbackResolverProvider).resolve(info);
      if (!_isCurrentRequest(requestId)) return;

      if (source == null) {
        _machine.dispatch(SourceResolutionFailed(
          'NOT_AVAILABLE',
          requestId: requestId,
        ));
        return;
      }

      _machine.dispatch(SourceResolved(
        info.id,
        source.streamUrl,
        requestId: requestId,
      ));
      if (_machine.state != PlaybackState.loading) return;

      final engine = _engine;
      if (engine == null) {
        _machine.dispatch(SourceResolutionFailed(
          'AUDIO_ENGINE_UNAVAILABLE',
          requestId: requestId,
        ));
        return;
      }

      await _serializeEngineOperation(() async {
        if (!_isCurrentRequest(requestId) || !identical(_engine, engine)) {
          return;
        }

        await engine.prepare(source);
        if (!_isCurrentRequest(requestId) || !identical(_engine, engine)) {
          return;
        }

        _machine.dispatch(MediaReady(requestId: requestId));
        if (_machine.state != PlaybackState.buffering) return;
        _machine.dispatch(PlayPressed());
        if (_machine.state != PlaybackState.playing) return;

        // just_audio's play Future completes when playback stops, not when
        // playback first starts. Do not await the whole song here.
        unawaited(engine.play().catchError(
          (Object error, StackTrace stackTrace) {
            if (_isCurrentRequest(requestId)) {
              _machine.dispatch(SourceResolutionFailed(
                'PLAYBACK_FAILED',
                requestId: requestId,
              ));
            }
          },
        ));
      });

      if (!_isCurrentRequest(requestId) ||
          _machine.state != PlaybackState.playing) {
        return;
      }

      if (info.title != null) {
        unawaited(_recent
            .record(
              info.id,
              info.title!,
              info.artist ?? '',
              info.artworkUrl,
              info.duration,
            )
            .catchError((_) {}));
      }
      _scrobbles.onPlay(info.id, DateTime.now().toUtc());
    } catch (_) {
      if (_isCurrentRequest(requestId)) {
        _machine.dispatch(SourceResolutionFailed(
          'PLAYBACK_SETUP_FAILED',
          requestId: requestId,
        ));
      }
    }
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
  Future<PlayableSource?> resolve(TrackInfo track);
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
    bool clearCurrentTrack = false,
    int? queueVersion,
  }) {
    return PlayerState(
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentTrack: clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      queueVersion: queueVersion ?? this.queueVersion,
    );
  }
}

/// The single global provider — one instance app-wide (§53.1).
final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
