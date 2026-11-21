import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/player/player_controller.dart';
import 'background_audio.dart';

/// Native background-audio bridge over audio_service.
///
/// Lock-screen/notification media controls dispatch commands straight to
/// the global PlayerController — the controller stays the single
/// playback authority (§53.1); this handler is only the OS surface.
class AudioServiceBridge extends audio.BaseAudioHandler
    implements BackgroundAudioBridge {
  final ProviderContainer container;

  AudioServiceBridge(this.container);

  PlayerController get _player =>
      container.read(playerControllerProvider.notifier);

  // ---- Lock-screen commands → PlayerController ---------------------

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  // ---- BackgroundAudioBridge (OS sync) ----------------------------

  @override
  Future<void> start() async {
    // Already initialized by the time this instance exists; nothing to do.
  }

  @override
  Future<void> update({
    required String title,
    required String artist,
    String? artworkUrl,
    required bool playing,
  }) async {
    final state = container.read(playerControllerProvider);

    playbackState.add(audio.PlaybackState(
      controls: [
        audio.MediaControl.skipToPrevious,
        playing ? audio.MediaControl.pause : audio.MediaControl.play,
        audio.MediaControl.skipToNext,
      ],
      systemActions: const {
        audio.MediaAction.seek,
        audio.MediaAction.seekForward,
        audio.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: playing
          ? audio.AudioProcessingState.ready
          : audio.AudioProcessingState.idle,
      playing: playing,
      updatePosition: state.position,
      bufferedPosition: state.position,
      speed: 1.0,
    ));

    mediaItem.add(audio.MediaItem(
      id: state.currentTrack?.id ?? 'current',
      title: title,
      artist: artist,
      duration: state.duration,
      artUri: artworkUrl != null ? Uri.tryParse(artworkUrl) : null,
    ));
  }

  @override
  Future<void> stop() => super.stop();
}

/// Starts audio_service with our handler; call once from bootstrap
/// before the first frame.
Future<AudioServiceBridge> startBackgroundAudio(
    ProviderContainer container) async {
  final bridge = await audio.AudioService.init(
    builder: () => AudioServiceBridge(container),
    config: const audio.AudioServiceConfig(
      androidNotificationChannelName: 'Breezze playback',
      androidNotificationChannelDescription:
          'Playback controls for Breezze',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidStopForegroundOnPause: true,
    ),
  );
  return bridge;
}
