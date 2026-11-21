/// Breezze playback state machine — spec §53.2.
///
/// A new start request supersedes every in-flight request. Resolver events
/// carry the request generation so stale network completions are ignored.
library;

enum PlaybackState {
  idle,
  resolving,
  loading,
  buffering,
  playing,
  paused,
  seeking,
  transitioning,
  ended,
  failed,
  interrupted,
  offline,
}

sealed class PlaybackEvent {}

class StopRequested extends PlaybackEvent {
  final int requestId;
  StopRequested({this.requestId = 0});
}

class StartRequested extends PlaybackEvent {
  final String trackId;
  final int requestId;
  StartRequested(this.trackId, {this.requestId = 0});
}

class SourceResolved extends PlaybackEvent {
  final String trackId;
  final String streamUrl;
  final int requestId;
  SourceResolved(this.trackId, this.streamUrl, {this.requestId = 0});
}

class SourceResolutionFailed extends PlaybackEvent {
  final String code;
  final int requestId;
  SourceResolutionFailed(this.code, {this.requestId = 0});
}

class MediaReady extends PlaybackEvent {
  final int requestId;
  MediaReady({this.requestId = 0});
}

class BufferingStarted extends PlaybackEvent {}
class PlayPressed extends PlaybackEvent {}
class PausePressed extends PlaybackEvent {}

class SeekRequested extends PlaybackEvent {
  final Duration position;
  SeekRequested(this.position);
}

class SeekCompleted extends PlaybackEvent {}

class TrackTransitioned extends PlaybackEvent {
  final String newTrackId;
  TrackTransitioned(this.newTrackId);
}

class TrackCompleted extends PlaybackEvent {}
class InterruptionDetected extends PlaybackEvent {}
class InterruptionEnded extends PlaybackEvent {}
class ConnectionLost extends PlaybackEvent {}
class ConnectionRestored extends PlaybackEvent {}

/// Centralized state machine. A response from an older request generation
/// cannot move the state machine belonging to the currently selected track.
class PlaybackStateMachine {
  PlaybackState _state = PlaybackState.idle;
  int _activeRequestId = 0;
  String? _activeTrackId;

  final void Function(PlaybackState previous, PlaybackState next)? onTransition;

  PlaybackStateMachine({this.onTransition});

  PlaybackState get state => _state;
  int get activeRequestId => _activeRequestId;
  String? get activeTrackId => _activeTrackId;

  PlaybackState dispatch(PlaybackEvent event) {
    final before = _state;
    _state = _reduce(_state, event);
    if (before != _state) onTransition?.call(before, _state);
    return _state;
  }

  PlaybackState _reduce(PlaybackState s, PlaybackEvent e) {
    // Selecting a new track supersedes any previous operation, regardless
    // of whether the old track was playing, paused, buffering or resolving.
    if (e is StopRequested) {
      _activeRequestId = e.requestId;
      _activeTrackId = null;
      return PlaybackState.idle;
    }

    if (e is StartRequested) {
      _activeRequestId = e.requestId;
      _activeTrackId = e.trackId;
      return PlaybackState.resolving;
    }

    if (e is SourceResolved) {
      if (e.requestId != _activeRequestId ||
          e.trackId != _activeTrackId ||
          s != PlaybackState.resolving) return s;
      return PlaybackState.loading;
    }

    if (e is SourceResolutionFailed) {
      if (e.requestId != _activeRequestId || s == PlaybackState.idle) {
        return s;
      }
      return PlaybackState.failed;
    }

    if (e is MediaReady) {
      if (e.requestId != _activeRequestId ||
          (s != PlaybackState.loading && s != PlaybackState.transitioning)) {
        return s;
      }
      return PlaybackState.buffering;
    }

    switch (s) {
      case PlaybackState.idle:
        if (e is TrackTransitioned) return PlaybackState.resolving;
        return s;
      case PlaybackState.resolving:
        if (e is ConnectionLost) return PlaybackState.offline;
        return s;
      case PlaybackState.loading:
        if (e is ConnectionLost) return PlaybackState.offline;
        return s;
      case PlaybackState.buffering:
        if (e is PlayPressed) return PlaybackState.playing;
        if (e is ConnectionLost) return PlaybackState.offline;
        return s;
      case PlaybackState.playing:
        if (e is PausePressed) return PlaybackState.paused;
        if (e is SeekRequested) return PlaybackState.seeking;
        if (e is TrackTransitioned) return PlaybackState.transitioning;
        if (e is TrackCompleted) return PlaybackState.ended;
        if (e is InterruptionDetected) return PlaybackState.interrupted;
        if (e is ConnectionLost) return PlaybackState.offline;
        return s;
      case PlaybackState.paused:
        if (e is PlayPressed) return PlaybackState.playing;
        if (e is TrackTransitioned) return PlaybackState.transitioning;
        return s;
      case PlaybackState.seeking:
        if (e is SeekCompleted) return PlaybackState.playing;
        if (e is ConnectionLost) return PlaybackState.offline;
        return s;
      case PlaybackState.transitioning:
        if (e is ConnectionLost) return PlaybackState.offline;
        return s;
      case PlaybackState.ended:
        if (e is TrackTransitioned) return PlaybackState.transitioning;
        return s;
      case PlaybackState.failed:
        return s;
      case PlaybackState.interrupted:
        if (e is InterruptionEnded) return PlaybackState.paused;
        return s;
      case PlaybackState.offline:
        if (e is ConnectionRestored) return PlaybackState.paused;
        return s;
    }
  }
}
