# Breezze Gap Register — product experience implementation

Status is evidence-based. A screen scaffold is not a complete feature until its repository, persistence or provider integration, real behavior, and tests are present.

| Area | Requirement | Status | Current evidence | Next action |
|---|---|---|---|---|
| Product identity | Monochrome Breezze identity and original marks | Implemented foundation | packages/design_system, apps/mobile/assets/icons | Complete SVG icon family |
| Home | Listen Now layout and honest first-run state | UI foundation | features/home/home_screen.dart | HomeRepository, listening history, recommendations |
| Browse | Discovery categories and selection | UI foundation | features/catalog/catalog_screens.dart | CatalogRepository, editorial and chart feeds |
| Radio | Radio landing and unavailable state | UI foundation | features/catalog/catalog_screens.dart | Licensed station provider, schedule and live stream |
| Library | Section selector and empty states | UI foundation | features/catalog/catalog_screens.dart | Drift persistence, favorites, playlists and sync |
| Search | Search input and clear behavior | UI foundation | features/catalog/catalog_screens.dart | SearchRepository, history and result types |
| Now Playing | Global player controls and progress surface | UI foundation | features/catalog/catalog_screens.dart | Track metadata/artwork, queue UI, lyrics and output routing |
| Mini-player | Persistent player bar opens Now Playing | Implemented foundation | widgets/bz_shell.dart | Device-level media session and artwork |
| Navigation | Phone tab bar and wide navigation rail | Implemented foundation | widgets/bz_shell.dart | go_router, deep links, route restoration |
| Downloads | Honest empty state | UI foundation | features/downloads/downloads_screen.dart | Connect DownloadManager job stream and file sink |
| Settings | Audio and account settings sections | UI foundation | features/settings/settings_screen.dart | Persist preferences; connect server entitlements |
| Playback core | State machine, queue, shuffle/repeat, crossfade, lyrics parser, Automix | Core implemented per existing tests | packages/audio_contracts | Engine integration and UI coverage |
| Provider access | Source adapters and source chain | Partial / blocked for production | packages/api_client | Secure backend, signer, provider compliance and rights validation |
| Backend | Auth, catalog API, user library, observability | Not started | No production backend in current tree | API scaffold, Postgres, auth and audit logs |
| Responsive UX | Tablet/desktop layouts | Partial | Wide navigation rail | Responsive content grids and desktop keyboard support |
| Accessibility | Screen reader, reduced motion, contrast, keyboard | Not audited | Semantics on primary tab controls | Full accessibility test pass |

## Implementation notes

- All music screens use the single global Riverpod PlayerController; no screen may instantiate a second player.
- Placeholder content must be labeled as such or removed. Do not ship fake charts, radio streams, listening history or recommendations as real user data.
- The product experience specification is in docs/PRODUCT_EXPERIENCE.md.
- Do not mark a row fully implemented until behavior and tests provide evidence.
