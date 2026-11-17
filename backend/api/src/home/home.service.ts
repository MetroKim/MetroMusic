import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

export interface HomeSection {
  sectionType: 'recently_played' | 'favorites';
  title: string;
  layout: 'rail' | 'grid';
  trackIds: string[];
}

@Injectable()
export class HomeService {
  constructor(private readonly prisma: PrismaService) {}

  async feed(userId: string): Promise<HomeSection[]> {
    const [recent, favorites] = await Promise.all([
      this.prisma.recentlyPlayed.findMany({
        where: { userId },
        orderBy: { playedAt: 'desc' },
        take: 50,
        select: { trackId: true },
      }),
      this.prisma.favorite.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 12,
        select: { trackId: true },
      }),
    ]);

    // Dedup by track, keep the most recent play of each, take 12
    // (RecentStore rail contract, Plan §5.5).
    const seen = new Set<string>();
    const recentTrackIds: string[] = [];
    for (const r of recent) {
      if (seen.has(r.trackId)) continue;
      seen.add(r.trackId);
      recentTrackIds.push(r.trackId);
      if (recentTrackIds.length === 12) break;
    }

    const sections: HomeSection[] = [];

    if (recentTrackIds.length > 0) {
      sections.push({
        sectionType: 'recently_played',
        title: 'Recently Played',
        layout: 'rail',
        trackIds: recentTrackIds,
      });
    }

    if (favorites.length > 0) {
      sections.push({
        sectionType: 'favorites',
        title: 'Your Favorites',
        layout: 'rail',
        trackIds: favorites.map((f) => f.trackId),
      });
    }

    return sections;
  }

  async recordPlay(userId: string, trackId: string) {
    // Every play is its own history row; the rail dedups in feed().
    await this.prisma.recentlyPlayed.create({
      data: { userId, trackId },
    });
    await this.prisma.listeningEvent.create({
      data: { userId, trackId },
    });
  }
}
