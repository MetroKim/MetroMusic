# Breezze

Music discovery, streaming, downloads and word-synced lyrics in one Flutter codebase.

## Features

- Search: live results, keyless, with artwork
- Stream: highest-bitrate audio via native engine (ExoPlayer / AVFoundation)
- Now Playing: breathing artwork, transport controls, seek, word-synced karaoke lyrics
- Background audio: lock-screen controls and notification (Android/iOS via audio_service, no-op elsewhere)
- Download: offline library (audio.m4a + cover.jpg + lyrics.lrc per track) with live byte-accurate progress
- Favorites and history: persisted locally; Home rails show real Recently Played + Favorites
- Design: monochrome token system, light and dark, Atmosphere materials

## Run it

Requires Flutter 3.22+.

Steps:

1. `git clone -b breezze https://github.com/MetroKim/MetroMusic.git`
2. `cd MetroMusic/apps/mobile`
3. `flutter create .` (generates android/, ios/, web/ runners)
4. `flutter pub get`
5. `flutter analyze` (should be clean)
6. `flutter test` (runs the package test suites)
7. `flutter run` (no keys, no defines; works out of the box)

### Background audio on Android

After `flutter create .`, add this service block inside the application element of `android/app/src/main/AndroidManifest.xml`:

```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>
<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

And these permissions before the application element:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

## Architecture

```
apps/mobile                  Flutter app
packages/
  design_system/             tokens, Atmosphere materials, theme
  audio_contracts/           player state machine, queue, lyrics, crossfade,
                             AutoMix, scrobbling, quality tiers (+ tests)
  api_client/                playback source, LRCLIB lyrics, downloads
                             library with progress, provider contracts
docs/
  architecture/              ADR-001
  audit/                     gap register (honest per-requirement status)
```

Keyless by design: search and playback run through youtube_explode_dart (no API key, no quota); lyrics through LRCLIB (free, community). No credentials to configure.

## Notes

- Breezze is an independent product, not affiliated with any streaming platform.
- Streams are resolved per-play; downloads store the highest-bitrate audio rendition available at download time.
- `flutter create .` generates the platform runners; they are build output, not committed.
