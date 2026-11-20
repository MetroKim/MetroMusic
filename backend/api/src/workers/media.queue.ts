import { Queue } from 'bullmq';

// Plan §10/§26 — the media pipeline queue. One queue per pipeline
// stage so failures in one stage never block the others.
export const MEDIA_QUEUE = 'media-pipeline';

export function mediaQueue(redisUrl: string): Queue {
  return new Queue(MEDIA_QUEUE, {
    connection: { url: redisUrl },
  });
}

export interface MediaJobData {
  jobId: string;
  submissionId: string;
  inputPath: string;
}
