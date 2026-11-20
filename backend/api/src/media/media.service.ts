import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { mediaQueue, MediaJobData } from '../workers/media.queue';

// Plan §10.1 — media ingestion. Upload registration creates the
// quarantined job record AND enqueues it; the worker (separate
// process) drives validate → transcode → publish.
@Injectable()
export class MediaService implements OnModuleInit {
  private queue: ReturnType<typeof mediaQueue> | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    const redisUrl = process.env.REDIS_URL ?? 'redis://localhost:6379';
    this.queue = mediaQueue(redisUrl);
  }

  async registerUpload(
    userId: string,
    dto: { submissionId: string; originalFilename: string; bytes: number },
  ) {
    const job = await this.prisma.mediaJob.create({
      data: {
        userId,
        submissionId: dto.submissionId,
        originalFilename: dto.originalFilename,
        bytes: dto.bytes,
        status: 'quarantined',
      },
    });

    if (this.queue) {
      await this.queue.add('pipeline', {
        jobId: job.id,
        submissionId: job.submissionId,
        // The uploader delivers to quarantine storage; the path is the
        // storage adapter's key. Real path comes from the upload
        // handler (multer/S3 presign) — stubbed as filename for now.
        inputPath: `quarantine/${job.id}/${dto.originalFilename}`,
      } satisfies MediaJobData);
    }

    return job;
  }

  async markStatus(jobId: string, status: string) {
    const result = await this.prisma.mediaJob.updateMany({
      where: { id: jobId },
      data: { status },
    });
    if (result.count === 0) throw new NotFoundException('JOB_NOT_FOUND');
    return { jobId, status };
  }

  async listJobs(userId: string) {
    return this.prisma.mediaJob.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
