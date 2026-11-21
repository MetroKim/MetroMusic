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
    // This endpoint creates a full-track URL. A preview grant is not a
    // full-stream entitlement; preview playback needs its own bounded URL.
    if (decision.previewOnly) {
      throw new NotAcceptableException('PREVIEW_ONLY');
    }
    const variant = decision.qualityRestriction ?? dto.requestedQuality ?? 'AAC_256';
    const signed = this.signer.createPlaybackUrl(
      dto.trackId,
      variant,
      decision.expiresAt,
    );
    return {
      trackId: dto.trackId,
      streamUrl: signed.url,
      expiresAt: signed.expiresAt,
      codec: variant === 'LOSSLESS' || variant === 'HI_RES' ? 'flac' : 'aac',
      attribution: decision.attribution,
      previewOnly: decision.previewOnly,
    };
  }
}
