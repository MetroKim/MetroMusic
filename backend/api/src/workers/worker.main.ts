import { startMediaWorker } from './media.worker';

// Worker entrypoint — run separately from the API so transcoding
// never blocks request handling. Package script: "start:workers".
const redisUrl = process.env.REDIS_URL ?? 'redis://localhost:6379';
const databaseUrl =
  process.env.DATABASE_URL ??
  'postgresql://breezze:breezze_dev@localhost:5432/breezze';

startMediaWorker(redisUrl, databaseUrl);

// eslint-disable-next-line no-console
console.log('breezze media worker running');
