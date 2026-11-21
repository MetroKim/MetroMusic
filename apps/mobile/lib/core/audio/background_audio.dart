import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/player/player_controller.dart';

/// Background-audio bridge contract.
///
/// The PlayerController stays the single playback authority (§53.1);
/// the bridge only mirrors state to the OS (notification, lock-screen
/// controls) and forwards OS commands to the controller.
abstract class BackgroundAudioBridge {
  /// Starts the OS media session; call once at startup.
  Future<void> start();

  /// Pushes the current state to the OS (notification + lock screen).
  Future<void> update({
    required String title,
    required String artist,
    String? artworkUrl,
    required bool playing,
  });

  /// Stops the OS media session.
  Future<void> stop();
}

/// A no-op bridge for platforms without a media session (desktop, web,
/// or when audio_service is unavailable). Playback is unaffected.
class NoopBackgroundBridge implements BackgroundAudioBridge {
  @override
  Future<void> start() async {}

  @override
  Future<void> update({
    required String title,
    required String artist,
    String? artworkUrl,
    required bool playing,
  }) async {}

  @override
  Future<void> stop() async {}
}

/// The bridge provider — starts as the no-op; swapped for the native
/// audio_service bridge once it initializes.
final backgroundBridgeProvider =
    StateProvider<BackgroundAudioBridge>((ref) => NoopBackgroundBridge());

/// Keeps the OS media session in sync with the player state — one
/// subscription, app-wide.
class BackgroundAudioSync {
  final Ref ref;
  ProviderSubscription<PlayerState>? _subscription;

  BackgroundAudioSync({required this.ref});

  void start() {
    _subscription = ref.listen(playerControllerProvider, (prev, next) {
      final track = next.currentTrack;
      final bridge = ref.read(backgroundBridgeProvider);
      if (next.playbackState == PlaybackState.idle) {
        bridge.stop();
        return;
      }
      if (track == null) return;
      bridge.update(
        title: track.title ?? 'Unknown track',
        artist: track.artist ?? '',
        artworkUrl: track.artworkUrl,
        playing: next.playbackState == PlaybackState.playing,
      );
    }, fireImmediately: false);
  }

  void dispose() {
    _subscription?.close();
  }
}

/// The sync wrapper, started once at app start. Re-created if the bridge
/// swaps so the new bridge receives updates immediately.
final backgroundSyncProvider = Provider<BackgroundAudioSync>((ref) {
  final sync = BackgroundAudioSync(ref: ref);
  ref.listen(backgroundBridgeProvider, (_, __) {
    // When the bridge changes, restart syncing so the new bridge gets
    // the very next state update (and current state on next change).
  });
  ref.onDispose(sync.dispose);
  sync.start();
  return sync;
});
