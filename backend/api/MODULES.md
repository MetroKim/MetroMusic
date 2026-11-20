# Backend Module Registry — Status

Date: 2026-11-17 · Branch: breezze · 24 modules active in AppModule

## Registered (24)

| # | Module | Endpoints | Notes |
|---|---|---|---|
| 1 | PrismaModule | — | Global DB access |
| 2 | AuthModule | /auth/* | Argon2id, rotating refresh, family revocation |
| 3 | UsersModule | /users/me | Profile, update, delete |
| 4 | CatalogModule | /catalog/* | Songs, albums, artists reads |
| 5 | RightsModule | — | RightsDecisionService: territory → takedown → permission → window |
| 6 | PlaybackModule | /playback/resolve | Rights-gated, HMAC-signed source |
| 7 | LibraryModule | /library/favorites | Favorites CRUD, user-scoped |
| 8 | SearchModule | /search | Title/artist/album contains |
| 9 | PlaylistsModule | /playlists/* | Ownership-scoped CRUD + ordering |
| 10 | DownloadsModule | /downloads/* | Rights-gated authorization + records |
| 11 | HomeModule | /home, /home/plays | Typed feed sections + play recording |
| 12 | LyricsModule | /lyrics, translations | Rights-gated lyrics.display |
| 13 | RadioModule | /radio/* | Stations + programs |
| 14 | RecommendationsModule | /recommendations | Deterministic artist affinity, no ML |
| 15 | OnboardingModule | /onboarding/preferences | Persisted user preferences |
| 16 | ReplayModule | /replay | Top songs/artists from events |
| 17 | SocialModule | /social/* | Follow/unfollow/following/followers |
| 18 | ClassicalModule | /classical/* | Composer → Work → Movement |
| 19 | AdminModule | /admin/* | Dashboard, takedowns, roles — RBAC gate PENDING |
| 20 | ProvidersModule | /providers/* | Registry + honest-result adapters |
| 21 | NotificationsModule | /notifications/* | Tokens, history, read state |
| 22 | ModerationModule | /moderation/* | Reports + resolution |
| 23 | ArtistPortalModule | /artist-portal/* | Claims + analytics |
| 24 | DistributorModule | /distributor/* | Release submissions + validation |
| 25 | MediaModule | /media/* | Ingestion job records |

## Skipped (per free-app decision)

- SubscriptionsModule — Breezze is fully free, no paywall
- PaymentsModule — no billing

## Schema

31 models, 0 subscription/billing tables.

## Known gaps (honest)

1. Admin RBAC role-gate — endpoints authenticated but not yet admin-only
2. FFmpeg transcoding workers — MediaJob records exist, processors land with workers phase
3. Push delivery (FCM/APNs) — records exist, delivery is a stub
4. Search is `contains`-based; pg_trgm + FTS upgrade when measured need appears
5. E2E tests + seed data — test phase
6. `.github/workflows/backend-ci.yml` — file ready, GitHub workflow-scope write blocked; add manually

## Verification command

```bash
cd backend/api
npm install && npx prisma generate && npx tsc --noEmit
# zero output = clean compile
```
