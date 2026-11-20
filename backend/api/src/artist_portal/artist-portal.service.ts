import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Plan §15.16 — artist claim, analytics, release management seams.
@Injectable()
export class ArtistPortalService {
  constructor(private readonly prisma: PrismaService) {}

  async claim(userId: string, artistId: string) {
    const artist = await this.prisma.artist.findUnique({
      where: { id: artistId },
    });
    if (!artist) throw new NotFoundException('ARTIST_NOT_FOUND');

    const existing = await this.prisma.artistClaim.findFirst({
      where: { artistId, status: 'approved' },
    });
    if (existing) {
      throw new NotFoundException('ARTIST_ALREADY_CLAIMED');
    }

    return this.prisma.artistClaim.create({
      data: {
        userId,
        artistId,
        status: 'pending',
      },
    });
  }

  async myClaims(userId: string) {
    return this.prisma.artistClaim.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async analytics(userId: string) {
    const claims = await this.prisma.artistClaim.findMany({
      where: { userId, status: 'approved' },
      select: { artistId: true },
    });
    if (claims.length === 0) return { artists: [], totals: { plays: 0 } };

    const artistIds = claims.map((c) => c.artistId);
    const tracks = await this.prisma.track.findMany({
      where: { artistId: { in: artistIds } },
      select: { id: true, title: true },
    });
    const trackIds = tracks.map((t) => t.id);
    const events = await this.prisma.listeningEvent.findMany({
      where: { trackId: { in: trackIds } },
      select: { trackId: true },
    });

    const playsByTrack = new Map<string, number>();
    for (const e of events) {
      playsByTrack.set(e.trackId, (playsByTrack.get(e.trackId) ?? 0) + 1);
    }

    return {
      artists: artistIds,
      totals: { plays: events.length },
      topTracks: tracks
        .map((t) => ({
          id: t.id,
          title: t.title,
          plays: playsByTrack.get(t.id) ?? 0,
        }))
        .sort((a, b) => b.plays - a.plays)
        .slice(0, 10),
    };
  }
}
