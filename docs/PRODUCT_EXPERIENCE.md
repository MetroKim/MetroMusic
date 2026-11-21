# Breezze Product Experience & UI Implementation Plan

> Product reference: the uploaded Apple Music feature inventory. This document translates its interaction patterns into Breezze's own product language. It is not a pixel-for-pixel recreation and does not use Apple's assets, copy, private APIs, or trade dress.

## Product principles

1. **Breezze-first identity.** Keep the monochrome black/white visual system, existing B-note/ribbon marks, semantic design tokens, and restrained Atmosphere surfaces. Do not introduce generic neon gradients, decorative AI aesthetics, or emoji icons.
2. **Music is the content.** Artwork, artist names, album titles, metadata, and playback state carry the visual hierarchy. Use square artwork with consistent crop and radius; use real metadata when a catalog source is connected.
3. **One playback authority.** All screens dispatch playback commands through the global Riverpod PlayerController. Navigation must not recreate or reset playback.
4. **Honest data states.** Never present fabricated tracks, charts, radio broadcasts, listening history, or recommendations as live data. Use explicit empty/loading/error states until a repository/API supplies them.
5. **Progressive disclosure.** Primary actions are visible; secondary actions live in contextual menus or bottom sheets. Do not overload the Home screen or foreground subscription prompts before users understand the product.
6. **Responsive by design.** Phone uses bottom navigation; wider layouts should move to a navigation rail/sidebar and use multi-column content while preserving the same information architecture.

## Primary information architecture

| Destination | Purpose | Main content |
|---|---|---|
| Home / Listen Now | Personal listening hub | Recently played, recommendations, mixes, saved stations, Replay |
| Browse | Editorial and catalog discovery | New releases, latest additions, charts, genres, moods, music videos, concerts |
| Radio | Live and programmed listening | Featured stations, station directory, show schedules, station detail |
| Library | User-owned/saved collection | Playlists, Artists, Albums, Songs, Genres, Compilations, Downloads |
| Search | Global catalog discovery | Search input, recent searches, suggestions, songs, albums, artists, playlists |
| Now Playing | Playback focus | Artwork, track metadata, transport, scrubber, queue, lyrics, output, playback modes |

Downloads remains accessible from Library and may also remain a top-level shortcut on compact layouts.

## Screen specifications

### Home / Listen Now
- Header: Breezze wordmark, profile entry, optional contextual actions.
- Greeting/title: Listen Now.
- Content rails: Recently Played, Made For You, Heavy Rotation, New Releases, Stations, Shared With You (only when supported), Replay (when available).
- Each rail has a clear title and a "See all" affordance when a full collection route exists.
- Cards open the appropriate album, playlist, artist, or station detail. Play actions use the global player.
- If personalization is unavailable, show a useful first-run state with Search/Browse entry points; do not show fake recommendations.

### Browse
- Editorial hero only when a real editorial feed is configured.
- Discovery groups: New, Charts, Genres, Moods & Activities, Music Videos, Concerts.
- Charts support global/territory and genre filters only when the backend provides those datasets.
- Genre and mood pages are browseable collections, not decorative category tiles.
- Row expansion opens a full collection view; it must not be a nonfunctional arrow.

### Radio
- Featured station area followed by a station directory.
- Station detail includes description, live/on-demand state, current show, schedule, related stations, share, and save-to-library.
- Distinguish live broadcast from on-demand episodes.
- No station is marked Live unless a stream/session is actually available.

### Library
- Filterable sections: Playlists, Artists, Albums, Songs, Genres, Compilations, Downloads.
- Users can reorder/show/hide optional sections.
- Empty states explain how to save music and link to Browse/Search.
- Item menus: Play, Play Next, Add to Playlist, Remove from Library, Share, Download/Remove Download, and Rename/Delete for owned playlists where applicable.
- Favorites are a first-class saved collection; downloaded state is separate from library membership.

### Search
- Global search with clear and cancel actions.
- Search scopes: All Catalog and Your Library.
- Recent searches are local and clearable.
- Result groups: Top Result, Songs, Albums, Artists, Playlists, Videos, and Stations where supported.
- Song rows show artwork, title, artist, duration, explicit flag, availability/quality badges, favorite/download state, and contextual menu.
- Empty, loading, offline, and no-results states are distinct.

### Album / Playlist / Artist detail
- Hero artwork and metadata, followed by primary Play/Shuffle actions.
- Contextual menu: Add/Remove from Library, Add to Playlist, Share, Download, and report/unavailable actions where appropriate.
- Album pages: tracklist, release metadata, credits, related albums.
- Playlist pages: owner, description, tracklist, collaborative status if implemented.
- Artist pages: top songs, albums, singles/EPs, similar artists, and upcoming concerts if a concert provider exists.
- Track rows consistently expose play, favorite, add, download, and more actions.

### Now Playing and mini-player
- Mini-player remains visible above navigation while a playback session exists; tapping it opens Now Playing.
- Now Playing: large artwork, title/artist, favorite, more, progress scrubber, elapsed/remaining time, previous/play-pause/next, shuffle, repeat, queue, lyrics, output route, and volume where supported.
- Lyrics view supports line-synced and word-synced formats when available; unavailable lyrics have a clear fallback.
- Queue supports reorder, remove, play-next, and clear actions.
- Sleep timer, crossfade, gapless, and Automix are exposed only when the engine/provider supports them.
- Playback controls always call PlayerController; UI must not maintain a second player state.

## Shared component and visual system

- Use the existing packages/design_system semantic tokens as the only source for colors, spacing, typography, radii, and motion.
- Keep surfaces monochrome and restrained. Atmosphere blur/translucency is reserved for floating navigation, mini-player, and overlays; content cards remain legible and mostly opaque.
- Artwork: square aspect ratio, consistent crop, token radius, no stretched images.
- Navigation and action icons: replace generic/emoji symbols with a consistent original SVG icon set. Maintain 20/24 px optical sizes and clear selected/disabled states.
- Components: BzArtwork, BzTrackRow, BzAlbumCard, BzContentRail, BzSectionHeader, BzEmptyState, BzContextMenu, BzTabBar, BzMiniPlayer, BzPlaybackControls, BzQualityBadge.
- Motion: short 160 ms feedback, 240 ms navigation, 320 ms sheets, 360 ms artwork transitions; respect reduced-motion settings.
- Accessibility: semantic labels, minimum 48 dp touch targets, contrast-safe text, keyboard support on desktop, screen-reader announcements for playback and download state.

## Domain and data contracts to add

- Catalog: Track, Album, Artist, Playlist, Genre, Mood, Station, Episode, EditorialCollection.
- User library: LibraryItem, Favorite, PlaylistMembership, DownloadRecord, ListeningHistory, RecentSearch.
- Playback: PlaybackSession, QueueEntry, PlaybackMode, AudioOutput, LyricsDocument.
- Every catalog entity uses a stable Breezze ID plus provider mappings. Provider IDs must never be treated as canonical IDs.
- Repositories: HomeRepository, CatalogRepository, SearchRepository, RadioRepository, LibraryRepository, DownloadRepository, LyricsRepository.
- Repositories return typed loading/data/empty/error states and are injected through Riverpod providers.
- All user-specific persistence is scoped to the authenticated user. Provider credentials and signing secrets remain server-side.

## Delivery sequence

### P0 — Core product shell
1. Fix app bootstrap and shell entry-point consistency.
2. Implement real Home, Browse, Radio, Library, and Search routes.
3. Connect mini-player tap to Now Playing; retain one global PlayerController.
4. Add empty/loading/error states and remove sample content that could be mistaken for real catalog data.
5. Add screen/widget tests for navigation and player persistence.

### P1 — Catalog experience
1. Implement typed catalog models and repositories.
2. Add album, playlist, artist, genre, mood, and station detail routes.
3. Implement global search and contextual item menus.
4. Add persistent favorites and library using a local database plus authenticated sync.
5. Add original SVG navigation/action icon set and shared artwork/track-row components.

### P2 — Listening depth
1. Lyrics UI and translation/pronunciation affordances where licensed data exists.
2. Queue editing, shuffle/repeat/autoplay, sleep timer, and output routing.
3. Radio schedules, on-demand episodes, and station saving.
4. Charts, Replay, concerts, music videos, and collaborative playlists only after reliable providers/backend support them.

### P3 — Platform parity and polish
1. Responsive tablet/desktop navigation and layouts.
2. Background playback, lock-screen/media-session integration, and platform output controls.
3. Offline-first library/download management with rights and entitlement checks.
4. Localization, accessibility audit, performance profiling, analytics/privacy controls.

## Acceptance criteria

- All five primary destinations are reachable and retain state during navigation.
- Tapping the mini-player opens Now Playing without creating a second player.
- No visible control is decorative: every enabled action has a real outcome; unsupported actions are disabled or clearly marked unavailable.
- No mock track, station, chart, recommendation, or history is represented as live user data.
- All colors, spacing, radii, typography, and motion come from design tokens.
- Search, library, and playback UI handle loading, empty, offline, error, and populated states.
- The feature gap register is updated only after behavior and tests exist.
