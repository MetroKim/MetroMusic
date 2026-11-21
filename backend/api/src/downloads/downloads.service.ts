import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RightsDecisionService } from '../rights/rights-decision.service';
import { MediaSigner } from '../playback/media-signer.service';

@Injectable()
export class DownloadsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rights: RightsDecisionService,
    private readonly signer: MediaSigner,
  ) {}

  async authorizeAndRecord(
    userId: string,
    dto: { trackId: string; territory: string },
  ) {
    const decision = await this.rights.decide({
      userId,
      trackId: dto.trackId,
      action: 'download',
      territory: dto.territory,
    });

    if (!decision.allowed || decision.previewOnly) {
      return {
        allowed: false,
        reason: decision.previewOnly ? 'PREVIEW_ONLY' : decision.reason,
        url: null,
      };
    }

    const signed = this.signer.createPlaybackUrl(
      dto.trackId,
      'download',
      decision.expiresAt,
    );
    const record = await this.prisma.downloadRecord.upsert({
      where: { userId_trackId: { userId, trackId: dto.trackId } },
      create: {
        userId,
        trackId: dto.trackId,
        expiresAt: decision.expiresAt,
      },
      update: { expiresAt: decision.expiresAt },
    });

    return {
      allowed: true,
      reason: 'OK',
      url: signed.url,
      recordId: record.id,
      expiresAt: signed.expiresAt,
      rightsExpiresAt: decision.expiresAt,
      attribution: decision.attribution,
    };
  }

  async list(userId: string) {
    return this.prisma.downloadRecord.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        trackId: true,
        status: true,
        createdAt: true,
        expiresAt: true,
      },
    });
  }

  async remove(userId: string, trackId: string) {
    const result = await this.prisma.downloadRecord.deleteMany({
      where: { userId, trackId },
    });
    if (result.count === 0) {
      throw new NotFoundException('DOWNLOAD_NOT_FOUND');
    }
    return { removed: true };
  }
}
