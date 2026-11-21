<div align="center">

# MetroMusic

### Breezze — your music, gathered in one place.

A cross-platform music discovery and listening client built with Flutter, Dart and a shared audio core.

</div>

> Breezze is an independent product. It is not affiliated with Apple, YouTube, Google, Spotify, or any streaming provider. Music-source integrations must comply with provider terms, territory restrictions, and applicable rights.

## Product

Breezze brings together music discovery, a personal library, playback, lyrics, offline listening, and cross-platform experiences under its own visual identity.

The product experience plan lives in [docs/PRODUCT_EXPERIENCE.md](docs/PRODUCT_EXPERIENCE.md). The feature-by-feature implementation status is tracked in [docs/audit/gap-register.md](docs/audit/gap-register.md).

## Current client architecture

    MetroMusic/
    ├── apps/mobile/                 # Flutter consumer app
    │   ├── lib/features/            # Home, catalog, player, downloads, settings
    │   ├── lib/widgets/             # Breezze shell and brand components
    │   └── assets/icons/            # Original Breezze vector marks
    ├── packages/
    │   ├── design_system/           # Semantic colors, typography, spacing, motion
    │   ├── audio_contracts/         # Playback state, queue, lyrics, AutoMix
    │   └── api_client/              # Provider adapters, source chain, downloads
    ├── docs/
    │   ├── PRODUCT_EXPERIENCE.md
    │   ├── architecture/
    │   └── audit/
    └── shared/, sharedUi/, app/, desktop/ # Legacy Chordline/KMP reference modules

The accepted Flutter-first direction is documented in [ADR-001](docs/architecture/ADR-001-flutter-first-shared-codebase.md). The older Chordline Kotlin Multiplatform modules remain as reference material and are not the active Flutter app entry point.

## Product experience included

- Home / Listen Now
- Browse: new releases, charts, genres, moods, videos and concerts
- Radio: stations, live state and schedules
- Library: playlists, artists, albums, songs, genres and downloads
- Search across catalog and library
- Album, playlist and artist detail experiences (planned catalog integration)
- Mini-player and full Now Playing surface
- Queue, shuffle, repeat, lyrics, audio quality, crossfade and Automix foundations
- Light/dark monochrome design system and responsive navigation direction

Some screens are UI foundations awaiting real repositories and licensed catalog sources. The app intentionally shows explicit empty states rather than pretending sample content is live music.

## Getting started

Requires Flutter 3.22+ and a compatible Dart SDK.

    git clone https://github.com/MetroKim/MetroMusic.git
    cd MetroMusic/apps/mobile
    flutter pub get
    flutter run

Run package tests from the repository root:

    cd ../..
    flutter test packages/audio_contracts
    flutter test packages/api_client

## Source and rights policy

- Provider credentials, signing keys and privileged tokens must stay server-side.
- A track is playable only when the selected source is authorized for the user's territory and entitlement.
- Do not proxy, download, or re-host media without the relevant rights and provider authorization.
- If no valid source is available, show an unavailable state and permitted alternatives. Never substitute a different recording silently.

## License

See [LICENSE](LICENSE).
