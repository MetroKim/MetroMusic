import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Plan §15.17 — distributor release submissions, validation, delivery
// status. Ingestion workers (Plan §10) consume validated submissions.
@Injectable()
export class DistributorService {
  constructor(private readonly prisma: PrismaService) {}

  async submitRelease(
    userId: string,
    dto: {
      title: string;
      artistName: string;
      trackTitles: string[];
    },
  ) {
    const artist = await this.prisma.artist.upsert({
      where: { name: dto.artistName },
      create: { name: dto.artistName },
      update: {},
    });

    return this.prisma.releaseSubmission.create({
      data: {
        userId,
        title: dto.title,
        artistId: artist.id,
        trackCount: dto.trackTitles.length,
        status: 'submitted',
      },
    });
  }

  async mySubmissions(userId: string) {
    return this.prisma.releaseSubmission.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async validate(submissionId: string) {
    const submission = await this.prisma.releaseSubmission.findUnique({
      where: { id: submissionId },
    });
    if (!submission) throw new NotFoundException('SUBMISSION_NOT_FOUND');

    const errors: string[] = [];
    if (submission.title.trim().length === 0) errors.push('TITLE_EMPTY');
    if (submission.trackCount < 1) errors.push('NO_TRACKS');

    const status = errors.length > 0 ? 'invalid' : 'validated';
    await this.prisma.releaseSubmission.update({
      where: { id: submissionId },
      data: { status },
    });
    return { status, errors };
  }
}
