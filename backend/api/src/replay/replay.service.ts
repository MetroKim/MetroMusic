import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

export interface ReplaySummary {
  totalPlays: number;
  topSongIds: { id: string; plays: number }[];
  topArtistIds: { id: string; plays: number }[];
}

@Injectable()
export class ReplayService {
  constructor(private readonly prisma: PrismaService) {}

  async summary(userId: string): Promise<ReplaySummary> {
    const events = await this.prisma.listeningEvent.findMany({
      where: { userId },
      select: { trackId: true },
    });

    const songCounts = new Map<string, number>();
    for (const e of events) {
      songCounts.set(e.trackId, (songCounts.get(e.trackId) ?? 0) + 1);
    }

    const trackIds = [...songCounts.keys()];
    const tracks = trackIds.length
      ? await this.prisma.track.findMany({
          where: { id: { in: trackIds } },
          select: { id: true, artistId: true },
        })
    : [];

    const artistCounts = new Map<string, number>();
    for (const t of tracks) {
      const plays = songCounts.get(t.id) ?? 0;
      artistCounts.set(t.artistId, (artistCounts.get(t.artistId) ?? 0) + plays);
    }

    const topSongIds = [...songCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([id, plays]) => ({ id, plays }));

    const topArtistIds = [...artistCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([id, plays]) => ({ id, plays }));

    return {
      totalPlays: events.length,
      topSongIds,
      topArtistIds,
    };
  }
}
