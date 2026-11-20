import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RightsDecisionService } from '../rights/rights-decision.service';

@Injectable()
export class LyricsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rights: RightsDecisionService,
  ) {}

  async getLyrics(
    userId: string,
    dto: { trackId: string; territory: string },
  ) {
    const decision = await this.rights.decide({
      userId,
      trackId: dto.trackId,
      action: 'lyrics.display',
      territory: dto.territory,
    });

    if (!decision.allowed) {
      throw new NotFoundException(decision.reason);
    }

    const lyrics = await this.prisma.lyrics.findUnique({
      where: { trackId: dto.trackId },
    });
    if (!lyrics) throw new NotFoundException('LYRICS_NOT_FOUND');

    return {
      trackId: lyrics.trackId,
      plainText: lyrics.plainText,
      syncedLrc: lyrics.syncedLrc,
      attribution: decision.attribution,
    };
  }

  async getTranslations(lyricsId: string, language?: string) {
    return this.prisma.lyricTranslation.findMany({
      where: { lyricsId, ...(language ? { language } : {}) },
    });
  }
}
