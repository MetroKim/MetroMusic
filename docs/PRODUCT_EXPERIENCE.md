# Breezze Product Experience Plan

This specification applies the supplied music-app feature inventory to Breezze's independent product identity and the existing Flutter-first architecture. It describes target behavior; a listed capability is not considered shipped until its real data source, persistence, permissions, and tests exist.

## Product principles

- Breezze has its own monochrome visual identity. Use the existing design-system tokens, brand SVGs, glass/Atmosphere components, and restrained motion. Do not copy Apple's assets, labels, proprietary APIs, or trade dress.
- Music content leads the hierarchy: artwork, track/artist metadata, duration, availability, and playback actions.
- The global Riverpod PlayerController remains the only playback authority. Navigation must not recreate or reset playback.
- Use real provider/catalog results. Never fabricate tracks, radio stations, listening history, charts, or recommendations.
- Keep Breezze free. Do not introduce subscriptions, billing, paywalls, or premium-only controls.
- Respect source terms and rights. Use official playback surfaces where required; do not extract or re-host media without authorization.
- Provide loading, empty, offline, error, and populated states. A blank screen is not an acceptable failure state.

## Information architecture

| Area | Target capabilities |
|---|---|
| Home / Listen Now | Recently Played, Favorites, Made For You, New Releases, Replay, stations, editorial rails |
| Search | Songs, artists, albums, playlists, videos, stations; recent searches; clear and remove history |
| Library | Favorites, playlists, artists, albums, songs, genres, compilations, downloads |
| Browse | New releases, charts, genres, moods, music videos, concerts, editorial collections |
| Radio | Featured stations, station directory, live status, show schedules, on-demand episodes |
| Player | Mini-player, Now Playing, queue, lyrics, shuffle/repeat, seek, audio output, volume |
| Artist/album/playlist detail | Artwork hero, metadata, primary play actions, track lists, related content, contextual actions |
| Settings | Audio quality, playback preferences, downloads, account, privacy, accessibility |

## Screen behavior

### Home / Listen Now
- Personal rails are sourced from persisted listening history, favorites, and backend recommendations.
- First-run state directs users to Search/Browse. Hide empty rails rather than showing invented cards.
- Each rail card opens its entity; play starts a queue with the correct origin/context.

### Search
- Search the connected catalog source and display real track metadata/artwork.
- Keep recent searches on-device, newest first, deduplicated case-insensitively, capped at ten, individually removable, and clearable.
- Handle overlapping requests safely: stale responses must not replace newer results.
- Distinguish no-results from provider/network failures.
- Future catalog integration can add album, artist, playlist, video, and station result groups without changing the search-history contract.

### Library
- Favorites and downloads remain distinct. Favorites are saved catalog references; downloads are local media files with provider/rights constraints.
- Show real saved items from local storage and sync when authenticated.
- Playlist ownership and membership are enforced by the backend; a user must never read or mutate another user's library.

### Browse and Radio
- Only show editorial rails, charts, concerts, or radio streams when a verified provider/backend returns them.
- Live badges require a real live-state signal. Schedule times must include a timezone.
- Station and collection detail routes need real descriptions, artwork, playback state, and save/share actions.

### Player
- Mini-player displays current track artwork/title/artist and playback progress, and opens the full Now Playing screen.
- Now Playing exposes transport, seek, shuffle/repeat, queue, lyrics, output route, and volume only where the engine supports them.
- Queue operations use the global PlayerController/QueueManager.
- Lyrics are shown only when a licensed/authorized lyrics provider returns a matching track.

## Visual system and reusable components

- Source colors, type, spacing, radii, and motion from the existing design system.
- Use original Breezze SVG marks and iconography; no emoji icons.
- Use square, consistently cropped artwork with semantic fallback states.
- Use glass/blur only for floating controls, mini-player, and overlays; keep content surfaces readable.
- Keep tap targets at least 48 logical pixels, provide semantic labels, and respect reduced-motion settings.
- Reusable component targets: artwork, track row, entity card, content rail, section header, empty/error state, contextual menu, mini-player, playback controls, quality badge.

## Data and integration contracts

- Canonical catalog IDs are Breezze-owned. Provider IDs are mapped to canonical IDs and never used as database primary keys.
- User data (favorites, playlists, listening history, downloads, search preferences) is scoped by authenticated user on the server; local-only search history stays on-device.
- Backend modules already present include Catalog, Rights, Playback, Library, Search, Playlists, Downloads, Home, Lyrics, Radio, Recommendations, Replay, Social, Classical, Providers, Notifications, Moderation, Artist Portal, Distributor, and Media.
- Client repositories/adapters should isolate transport and provider behavior from widgets. Do not put credentials or signing secrets in the app.
- Every provider result must preserve source attribution and rights/territory restrictions.

## Delivery phases

1. **Product shell and navigation:** stable destinations, persistent state, responsive navigation, mini-player and Now Playing.
2. **Catalog discovery:** search history, search result groups, entity detail pages, catalog metadata/artwork, charts and editorial feeds.
3. **Personal library:** favorites, playlists, downloads, offline state, authenticated sync and conflict handling.
4. **Listening depth:** queue editing, lyrics, radio schedules, Replay, recommendations, output routing and playback preferences.
5. **Platform polish:** desktop/tablet layouts, accessibility, deep links, localization, performance and analytics/privacy controls.

## Acceptance criteria

- Every visible enabled control performs a real action; unsupported capabilities are disabled or clearly unavailable.
- Search history survives app restarts, is capped at ten, and supports deduplication/removal/clear.
- A slow older search cannot overwrite a newer search.
- No fabricated content is presented as real.
- All user-owned server records are protected by authenticated user scoping and ownership checks.
- Playback survives tab navigation and is controlled by one global PlayerController.
- UI states cover loading, empty, offline, provider error, and populated results.
- Product feature status is updated only with implementation and test evidence.
