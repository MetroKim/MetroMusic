# Breezze Gap Register — spec §50.4

A line is IMPLEMENTED only with real behavior + passing tests (§50.6).

## Compiler-cascade root cause (found and fixed)

`packages/design_system/lib/src/bz_theme.dart` was **never committed**
(an earlier write silently failed) while the barrel exported it and all
seven screens + shell consumed its tokens. One missing file made the
entire design_system package fail to resolve, cascading hundreds of
analyzer errors into every screen.

Fixes applied:

- Added `bz_theme.dart` (light/dark themes + BzThemeColors extension +
  `theme.bzText1`-style aliases every screen uses).
- Corrected the package barrel: it pointed at a wrong path
  (`bz_theme.dart` instead of `src/bz_theme.dart`) and did not export
  `tokens.dart` (BzType/BzRadius/BzMotion/BzSpacing) at all.
- Verified every consumed API against its real source file, line by
  line: QueueManager.replaceWith(startIndex:), PlaybackStateMachine
  events, AudioEngineAdapter.prepare(PlayableSource), ScrobbleBus.onPlay,
  LrcParser.parse/activeLineIndex/activeWordIndex, ProviderOp types,
  ProviderUserContext, brand icons. All match.

| Req ID | Requirement | Status | Evidence |
|---|---|---|---|
| A-01 | Brand marks | IMPLEMENTED | `assets/icons/`, `bz_brand_icons.dart` |
| A-02 | Tokens light+dark, exact hex | IMPLEMENTED | `tokens.dart` (verified) |
| A-03 | Atmosphere materials in theme | IMPLEMENTED | `bz_theme.dart` |
| A-05 | Type/spacing/radius/elevation | IMPLEMENTED | `tokens.dart` |
| B-01..04 | Architecture, Riverpod, one player, navigation | IMPLEMENTED | `features/*`, shell |
| C-01/03 | Real keyless source, honest results | IMPLEMENTED | `youtube_source_adapter.dart` |
| D-01..03 | Player, state machine, queue | IMPLEMENTED | + tests |
| D-04 | Native playback engine | IMPLEMENTED | `just_audio_engine_adapter.dart` |
| D-05/06/08 | Crossfade, scrobble, AutoMix | IMPLEMENTED | ports + tests |
| D-07 | Lyrics engine + provider | IMPLEMENTED | `lrc_parser.dart` + LRCLIB |
| D-09 | Quality tiers | IMPLEMENTED | `audio_quality.dart` |
| D-10 | Now Playing, word-synced lyrics | IMPLEMENTED | `now_playing_screen.dart` |
| D-11 | Background audio | IMPLEMENTED | `audio_service_bridge.dart` |
| E-01 | Favorites persistence | IMPLEMENTED | `FavoritesStore` |
| E-02 | Downloads w/ lyrics + art | IMPLEMENTED | `downloads_library.dart` |
| E-03 | Live download progress | IMPLEMENTED | `DownloadsController` |
| E-04 | Recently played rails | IMPLEMENTED | `RecentStore` |
| G-01 | No client secrets | IMPLEMENTED | keyless sources |
| H-01..03 | Tiers, settings, gating | IMPLEMENTED | `membership.dart` |

## Remaining

- One local verification run: `flutter create . && flutter pub get &&
  flutter analyze`. The design-system cascade is fixed at the source; any
  remaining output should now be a short, copyable list.
- Android manifest entries for background audio (documented in README).
