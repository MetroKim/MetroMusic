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
      const preview = await this.prisma.rightsUsagePermission.findFirst({
        where: { trackId: req.trackId, action: 'preview' },
      });
      if (preview) {
        return allowDecision({
          previewOnly: true,
          qualityRestriction: null,
        });
      }
      return denyDecision('NO_EXPLICIT_AUTHORIZATION');
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
