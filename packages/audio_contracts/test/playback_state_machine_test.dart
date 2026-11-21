import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaybackStateMachine (§53.2)', () {
    test('idle → resolving → loading → buffering → playing', () {
      final m = PlaybackStateMachine();
      expect(m.state, PlaybackState.idle);
      m.dispatch(StartRequested('t1'));
      expect(m.state, PlaybackState.resolving);
      m.dispatch(SourceResolved('t1', 'https://stream'));
      expect(m.state, PlaybackState.loading);
      m.dispatch(MediaReady());
      expect(m.state, PlaybackState.buffering);
      m.dispatch(PlayPressed());
      expect(m.state, PlaybackState.playing);
    });

    test('playing ↔ paused', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('t1'))
        ..dispatch(SourceResolved('t1', 'url'))
        ..dispatch(MediaReady())
        ..dispatch(PlayPressed());
      m.dispatch(PausePressed());
      expect(m.state, PlaybackState.paused);
      m.dispatch(PlayPressed());
      expect(m.state, PlaybackState.playing);
    });

    test('playing → seeking → playing', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('t1'))
        ..dispatch(SourceResolved('t1', 'url'))
        ..dispatch(MediaReady())
        ..dispatch(PlayPressed());
      m.dispatch(SeekRequested(const Duration(seconds: 30)));
      expect(m.state, PlaybackState.seeking);
      m.dispatch(SeekCompleted());
      expect(m.state, PlaybackState.playing);
    });

    test('playing → interrupted → (ended) paused', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('t1'))
        ..dispatch(SourceResolved('t1', 'url'))
        ..dispatch(MediaReady())
        ..dispatch(PlayPressed());
      m.dispatch(InterruptionDetected());
      expect(m.state, PlaybackState.interrupted);
      m.dispatch(InterruptionEnded());
      expect(m.state, PlaybackState.paused);
    });

    test('playing → offline → restored paused', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('t1'))
        ..dispatch(SourceResolved('t1', 'url'))
        ..dispatch(MediaReady())
        ..dispatch(PlayPressed());
      m.dispatch(ConnectionLost());
      expect(m.state, PlaybackState.offline);
      m.dispatch(ConnectionRestored());
      expect(m.state, PlaybackState.paused);
    });

    test('playing → ended', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('t1'))
        ..dispatch(SourceResolved('t1', 'url'))
        ..dispatch(MediaReady())
        ..dispatch(PlayPressed());
      m.dispatch(TrackCompleted());
      expect(m.state, PlaybackState.ended);
    });

    test('resolution failure → failed; can restart', () {
      final m = PlaybackStateMachine();
      m.dispatch(StartRequested('t1'));
      m.dispatch(SourceResolutionFailed('RIGHTS_NOT_AVAILABLE'));
      expect(m.state, PlaybackState.failed);
      m.dispatch(StartRequested('t1'));
      expect(m.state, PlaybackState.resolving);
    });

    test('a new selection supersedes an active playback state', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('first', requestId: 1))
        ..dispatch(SourceResolved('first', 'url-1', requestId: 1))
        ..dispatch(MediaReady(requestId: 1))
        ..dispatch(PlayPressed());

      m.dispatch(StartRequested('second', requestId: 2));
      expect(m.state, PlaybackState.resolving);
      expect(m.activeTrackId, 'second');
      expect(m.activeRequestId, 2);
    });

    test('late resolver response from an older request is ignored', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('first', requestId: 1))
        ..dispatch(StartRequested('second', requestId: 2));

      m.dispatch(SourceResolved('first', 'stale-url', requestId: 1));
      expect(m.state, PlaybackState.resolving);
      expect(m.activeTrackId, 'second');

      m.dispatch(SourceResolved('second', 'current-url', requestId: 2));
      expect(m.state, PlaybackState.loading);
    });

    test('late failure cannot fail the currently selected track', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('first', requestId: 10))
        ..dispatch(StartRequested('second', requestId: 11));

      m.dispatch(SourceResolutionFailed('OLD_REQUEST', requestId: 10));
      expect(m.state, PlaybackState.resolving);
      m.dispatch(SourceResolutionFailed('CURRENT_REQUEST', requestId: 11));
      expect(m.state, PlaybackState.failed);
    });

    test('new selection is accepted while previous request is loading', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('first', requestId: 1))
        ..dispatch(SourceResolved('first', 'url', requestId: 1));

      expect(m.state, PlaybackState.loading);
      m.dispatch(StartRequested('second', requestId: 2));
      expect(m.state, PlaybackState.resolving);
    });

    test('stop invalidates the active track and returns to idle', () {
      final m = PlaybackStateMachine()
        ..dispatch(StartRequested('t1', requestId: 1))
        ..dispatch(SourceResolved('t1', 'url', requestId: 1));
      m.dispatch(StopRequested(requestId: 2));
      expect(m.state, PlaybackState.idle);
      expect(m.activeTrackId, isNull);
      m.dispatch(SourceResolved('t1', 'late-url', requestId: 1));
      expect(m.state, PlaybackState.idle);
    });

  });
}
