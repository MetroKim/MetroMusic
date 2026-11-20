import { Worker, Job } from 'bullmq';
import { PrismaClient } from '@prisma/client';
import { MEDIA_QUEUE, MediaJobData } from './media.queue';
import { validate, transcodeAll } from './ffmpeg.stage';

// Plan §10.3 — the media pipeline worker. Consumes MediaJobData jobs,
// drives the Prisma MediaJob record through: quarantined → validating
// → processing → published (or failed). FFmpeg must exist in the image.
export function startMediaWorker(redisUrl: string, databaseUrl: string) {
  const prisma = new PrismaClient({ datasources: { db: { url: databaseUrl } } });
  const mediaRoot = process.env.MEDIA_ROOT ?? '/media';

  const worker = new Worker<MediaJobData>(
    MEDIA_QUEUE,
    async (job: Job<MediaJobData>) => {
      const { jobId, inputPath } = job.data;

      const record = await prisma.mediaJob.findUnique({ where: { id: jobId } });
      if (!record) throw new Error('JOB_RECORD_NOT_FOUND');

      await prisma.mediaJob.update({
        where: { id: jobId },
        data: { status: 'validating' },
      });

      const probe = await validate(inputPath);

      await prisma.mediaJob.update({
        where: { id: jobId },
        data: { status: 'processing' },
      });

      const outDir = `${mediaRoot}/${jobId}`;
      await transcodeAll(inputPath, outDir);

      await prisma.mediaJob.update({
        where: { id: jobId },
        data: { status: 'published' },
      });

      return {
        durationSec: probe.durationSec,
        bitrateKbps: probe.bitrateKbps,
        outDir,
      };
    },
    {
      connection: { url: redisUrl },
      concurrency: 2,
    },
  );

  worker.on('failed', async (job, err) => {
    if (job) {
      await prisma.mediaJob
        .update({
          where: { id: job.data.jobId },
          data: { status: 'failed' },
        })
        .catch(() => undefined);
    }
    // eslint-disable-next-line no-console
    console.error(`media job failed: ${err.message}`);
  });

  return worker;
}
