# Breezze Backend — Run Guide

Branch `breezze` · 24 modules · 31 schema models · media pipeline workers

## Quick start (full stack)

```bash
git clone -b breezze https://github.com/MetroKim/MetroMusic.git
cd MetroMusic/backend
docker compose up -d          # postgres, redis, api, worker
```

The API is then at `http://localhost:3000/api/v1` (Swagger at `/api/docs`).

## First-time setup (migrations + client)

```bash
cd backend/api
npm install
npx prisma migrate dev --name init
```

## Media pipeline

Upload flow: `POST /api/v1/media/uploads` registers the job (status
`quarantined`) and enqueues it. The worker process validates with
FFprobe, transcodes to HLS (aac_128 + aac_256), and marks the record
`published`. Job status is visible in `GET /api/v1/media/jobs`.

The worker needs FFmpeg — the compose `worker` service ships with it.
To run the worker locally outside Docker: `ffmpeg` must be on PATH,
then `npm run start:workers`.

## Free app

Breezze has no subscriptions and no billing — users get the full
experience for free. There are no subscription or payment tables in
the schema and no paywall UI in the apps.

## Known gaps (tracked in MODULES.md)

- Admin RBAC role-gate pending
- Search is contains-based (pg_trgm upgrade when measured)
- CI workflow file must be added manually (GitHub workflow-scope
  write is blocked for the agent)
