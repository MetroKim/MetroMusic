import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  ProviderAdapter,
  ProviderCapabilities,
  ProviderTrack,
} from './provider-adapter.interface';
import { ProviderResult, providerOk, providerError } from './provider-result';

// Plan §7.4 — the internal catalog adapter serves Breezze's own
// canonical catalog. Full streaming rights still flow through the
// RightsDecisionService; this adapter is metadata + availability only.
@Injectable()
export class InternalCatalogAdapter implements ProviderAdapter {
  readonly providerId = 'breezze_internal';
  readonly capabilities: ProviderCapabilities = {
    search: true,
    metadata: true,
    availability: true,
    playback: false,
    download: false,
  };

  constructor(private readonly prisma: PrismaService) {}

  async search(query: string): Promise<ProviderResult<ProviderTrack[]>> {
    try {
      const q = query.trim();
      if (q.length < 2) return providerOk([]);
      const tracks = await this.prisma.track.findMany({
        where: { title: { contains: q, mode: 'insensitive' } },
        include: { artist: true, album: true },
        take: 20,
      });
      return providerOk(
        tracks.map((t) => ({
          providerTrackId: t.id,
          title: t.title,
          artist: t.artist.name,
          durationSec: t.duration,
        })),
      );
    } catch (e) {
      return providerError('SEARCH_FAILED', String(e), true);
    }
  }

  async getTrack(providerTrackId: string): Promise<ProviderResult<ProviderTrack>> {
    const track = await this.prisma.track.findUnique({
      where: { id: providerTrackId },
      include: { artist: true },
    });
    if (!track) {
      return providerError('TRACK_NOT_FOUND', 'no such track', false);
    }
    return providerOk({
      providerTrackId: track.id,
      title: track.title,
      artist: track.artist.name,
      durationSec: track.duration,
    });
  }

  async getAvailability(
    providerTrackId: string,
    territory: string,
  ): Promise<ProviderResult<{ available: boolean }>> {
    const row = await this.prisma.territoryAvailability.findUnique({
      where: {
        trackId_territory: { trackId: providerTrackId, territory },
      },
    });
    return providerOk({ available: row !== null });
  }
}
