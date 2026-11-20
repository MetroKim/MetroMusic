import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

export interface RecommendationItem {
  trackId: string;
  reason: string;
}

@Injectable()
export class RecommendationsService {
  constructor(private readonly prisma: PrismaService) {}

  async forUser(userId: string): Promise<RecommendationItem[]> {
    // Deterministic rule (Plan §22.4): find the user's top artists by
    // listening events, then recommend their tracks that the user has
    // not recently played. No ML, fully explainable.
    const topArtists = await this.prisma.listeningEvent.groupBy({
      by: ['trackId'],
      where: { userId },
      _count: { trackId: true },
      orderBy: { _count: { trackId: 'desc' } },
      take: 50,
    });

    if (topArtists.length === 0) {
      return this.popularFallback();
    }

    const trackIds = topArtists.map((t) => t.trackId);
    const listenedTracks = await this.prisma.track.findMany({
      where: { id: { in: trackIds } },
      select: { artistId: true },
    });

    const artistIds = [
      ...new Set(listenedTracks.map((t) => t.artistId)),
    ].slice(0, 5);

    const recent = await this.prisma.recentlyPlayed.findMany({
      where: { userId },
      select: { trackId: true },
      take: 20,
    });
    const recentIds = new Set(recent.map((r) => r.trackId));

    const candidates = await this.prisma.track.findMany({
      where: { artistId: { in: artistIds } },
      take: 40,
    });

    return candidates
      .filter((t) => !recentIds.has(t.id))
      .slice(0, 12)
      .map((t) => ({
        trackId: t.id,
        reason: 'Because you listen to this artist',
      }));
  }

  private async popularFallback(): Promise<RecommendationItem[]> {
    const popular = await this.prisma.listeningEvent.groupBy({
      by: ['trackId'],
      _count: { trackId: true },
      orderBy: { _count: { trackId: 'desc' } },
      take: 12,
    });
    return popular.map((p) => ({
      trackId: p.trackId,
      reason: 'Popular on Breezze',
    }));
  }
}
