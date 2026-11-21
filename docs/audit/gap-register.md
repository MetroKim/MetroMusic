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

## Product experience rollout — 2026-11-21

The full target information architecture and UX behavior are documented in
`docs/PRODUCT_EXPERIENCE.md`. This rollout deliberately builds on the
existing `breezze` branch implementation rather than duplicating the
screens that already exist there.

| Requirement | Status | Evidence | Remaining work |
|---|---|---|---|
| Local recent-search history | IMPLEMENTATION ADDED — tests pending | `app/search_history_store.dart`, `features/search/search_screen.dart` | Run Flutter tests/analyze; then mark implemented |
| Search history deduplication and cap | IMPLEMENTATION ADDED — tests pending | Store caps at 10 and deduplicates case-insensitively | Verify tests |
| Remove one recent search / clear all | IMPLEMENTATION ADDED — tests pending | Search screen actions + store methods | Verify UI and persistence tests |
| Stale search response protection | IMPLEMENTED IN CODE — tests pending | Search generation token in SearchScreen | Add widget test for out-of-order results |
| Search failure vs no-results state | IMPLEMENTED IN CODE — tests pending | Provider/network error state separated from empty results | Add provider failure widget tests |
| Catalog result groups | PARTIAL | Existing keyless source returns track results; backend has catalog/search modules | Add canonical catalog-backed album/artist/playlist/video/station results |
| Browse editorial/charts/genres/moods | BACKEND/UI INTEGRATION PENDING | Backend Catalog and Recommendations modules exist | Connect typed client repositories and real feeds |
| Radio stations and programs | BACKEND/UI INTEGRATION PENDING | Radio backend module exists | Connect client repository, station detail, and playback rights |
| Album/artist/playlist detail | PARTIAL | Catalog models and backend read endpoints exist | Add detail routes and complete track/entity UI |
| Responsive desktop/tablet shell | NOT VERIFIED | Existing Flutter shell is phone-first | Implement and test responsive layouts |
| Accessibility/reduced motion | NOT AUDITED | Existing design-system motion/tokens and semantic controls | Run accessibility and reduced-motion audit |

### Verification gate

Do not promote the new search-history rows to IMPLEMENTED until these pass
from `apps/mobile`:

```bash
flutter pub get
flutter analyze
flutter test
```

Backend verification remains separate:

```bash
cd backend/api
npm install
npx prisma generate
npm run typecheck
npm test -- --runInBand
```

### Additional navigation and discovery work — 2026-11-21

| Requirement | Status | Evidence | Remaining work |
|---|---|---|---|
| Browse destination | UI + live genre search added — verification pending | `features/browse/browse_screen.dart` uses the existing keyless source adapter and global PlayerController | Add widget tests; add curated backend editorial/chart/genre feeds when available |
| Genre discovery | UI + provider integration added — verification pending | Afrobeats, Bongo Flava, Amapiano, Gospel, Hip-Hop, R&B, Jazz and Electronic search categories | Add backend-owned genre taxonomy and browse analytics |
| Radio station directory | API-connected UI added — verification pending | `features/radio/radio_screen.dart` reads the existing public `/radio/stations` endpoint | Add widget tests and real station artwork |
| Radio program details | API-connected UI added — verification pending | Station detail reads `/radio/stations/:id` and renders returned programs | Add schedule timezone formatting and pagination |
| Radio playback | NOT IMPLEMENTED | Current PlayerController resolves catalog track IDs, not radio station stream sessions | Add a separate authorized radio playback contract and engine session type |
| Primary navigation | Browse and Radio added to IndexedStack shell | `widgets/bz_shell.dart` | Validate small-screen horizontal tab navigation and wide layouts |

Browse search results are provider search results for the selected genre. They are
not presented as official charts, editorial playlists, or platform-curated
rankings. Radio station cards show the backend's live flag but do not expose a
play action until station playback is supported by the audio engine.


## Engineering completion backlog — 2026-11-21

The prioritized completion plan and critical defect register now live in
`docs/ROADMAP_AND_BUG_BACKLOG.md`. It separates confirmed code defects from
items that require migration/runtime verification and defines P0/P1/P2 work,
regression coverage, exit gates and the recommended implementation order.

**New release blockers identified during source inspection:**
- ProviderContainer/audio-engine ownership currently occurs inside
  `BreezzeShell.build()`; lifecycle ownership must be stabilized.
- Playback resolver operations have no request generation/cancellation
  guard, and the state machine does not accept a new start from several
  active states.
- Search history persistence errors were caught as if they were provider
  network errors; the SearchScreen now treats history as best-effort and
  continues the provider request when local persistence fails (test pending).
- Radio is metadata/schedule UI only; stream playback is not implemented.
- The inspected Prisma schema still contains
  `@@unique([userId, trackId])` on `RecentlyPlayed`; reconcile it with
  the migration history and intended repeated-play semantics before
  changing the schema.

Do not treat these findings as fixed. The Flutter/backend validation suite
has not been run in this environment. See the backlog for exact tests and
release acceptance criteria.


## P0 playback stabilization — implementation started

| Defect | Status | Evidence | Remaining verification |
|---|---|---|---|
| ProviderContainer recreated during shell build | FIX APPLIED — tests pending | `main.dart` now provides one root ProviderScope; `BreezzeShell` no longer creates a private container; `BreezzeAppRoot` owns engine attach/dispose and the migration container | Widget test auth transitions/rebuilds and exactly-once engine disposal; analyzer/runtime verification |
| Stale playback resolver responses | FIX APPLIED — tests added | `PlayerController` uses request generations and ignores stale resolver results | Execute fake-resolver tests; add detach and engine-error cases |
| Native prepare operations racing | FIX APPLIED — tests added | PlayerController serializes prepare/play engine mutations and rechecks request generation before/after prepare | Execute delayed-prepare race test on CI and real device |
| State machine rejects a new selection from active states | FIX APPLIED — tests added | `PlaybackStateMachine` treats each new start as superseding and rejects stale request IDs | Execute package tests and expand transition matrix |
| Playback Future awaited for entire song | FIX APPLIED — test pending | Controller no longer awaits the long-lived just_audio play Future as if it meant “started” | Verify actual just_audio behavior on Android/iOS and ensure async engine errors surface |
