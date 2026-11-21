import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  RightsDecision,
  RightsRequest,
  denyDecision,
  allowDecision,
} from './rights-decision.types';

@Injectable()
export class RightsDecisionService {
  constructor(private readonly prisma: PrismaService) {}

  async decide(req: RightsRequest): Promise<RightsDecision> {
    const available = await this.prisma.territoryAvailability.findFirst({
      where: { trackId: req.trackId, territory: req.territory },
    });
    if (!available) return denyDecision('NOT_AVAILABLE_IN_TERRITORY');

    const takedown = await this.prisma.contentTakedownCase.findFirst({
      where: { trackId: req.trackId, status: 'active' },
    });
    if (takedown) return denyDecision('TAKEDOWN_ACTIVE');

    const permission = await this.prisma.rightsUsagePermission.findFirst({
      where: { trackId: req.trackId, action: req.action },
    });

    if (!permission && req.action === 'metadata.display') {
      return allowDecision({ qualityRestriction: null });
    }

    if (!permission) {
      // A preview grant can never authorize downloads, caching or other
      // full-content actions. It is only a limited fallback for stream.full.
      if (req.action !== 'stream.full') {
        return denyDecision('NO_EXPLICIT_AUTHORIZATION');
      }

      const preview = await this.prisma.rightsUsagePermission.findFirst({
        where: { trackId: req.trackId, action: 'preview' },
      });
      if (!preview) return denyDecision('NO_EXPLICIT_AUTHORIZATION');

      // Preview permissions have their own validity window. A stale or
      // future preview grant must never be treated as active authorization.
      const now = new Date();
      if (preview.startAt && preview.startAt > now) {
        return denyDecision('RIGHTS_WINDOW_NOT_OPEN');
      }
      if (preview.endAt && preview.endAt < now) {
        return denyDecision('RIGHTS_EXPIRED');
      }

      const attribution = await this.prisma.providerAttribution.findFirst({
        where: { trackId: req.trackId },
      });
      return allowDecision({
        previewOnly: true,
        qualityRestriction: null,
        expiresAt: preview.endAt ?? null,
        attribution: attribution?.text ?? null,
      });
    }

    const now = new Date();
    if (permission.startAt && permission.startAt > now) {
      return denyDecision('RIGHTS_WINDOW_NOT_OPEN');
    }
    if (permission.endAt && permission.endAt < now) {
      return denyDecision('RIGHTS_EXPIRED');
    }

    const attribution = await this.prisma.providerAttribution.findFirst({
      where: { trackId: req.trackId },
    });

    return allowDecision({
      qualityRestriction: null,
      expiresAt: permission.endAt ?? null,
      attribution: attribution?.text ?? null,
    });
  }
}
