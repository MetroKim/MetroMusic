import { Injectable, NotAcceptableException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RightsDecisionService } from '../rights/rights-decision.service';
import { MediaSigner } from './media-signer.service';

@Injectable()
export class PlaybackResolveService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rights: RightsDecisionService,
    private readonly signer: MediaSigner,
  ) {}

  async resolve(
    userId: string | null,
    dto: { trackId: string; territory: string; requestedQuality?: string },
  ) {
    const decision = await this.rights.decide({
      userId,
      trackId: dto.trackId,
      action: 'stream.full',
      territory: dto.territory,
    });
    if (!decision.allowed) {
      throw new NotAcceptableException(decision.reason);
    }
    const variant = decision.qualityRestriction ?? dto.requestedQuality ?? 'AAC_256';
    return {
      trackId: dto.trackId,
      streamUrl: this.signer.signPlaybackUrl(dto.trackId, variant),
      expiresAt: new Date(Date.now() + 6 * 3600 * 1000),
      codec: variant === 'LOSSLESS' || variant === 'HI_RES' ? 'flac' : 'aac',
      attribution: decision.attribution,
      previewOnly: decision.previewOnly,
    };
  }
}
