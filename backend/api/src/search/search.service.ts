import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class SearchService {
  constructor(private readonly prisma: PrismaService) {}

  async search(query: string) {
    const q = query.trim();
    if (q.length < 2) {
      return { tracks: [], artists: [], albums: [] };
    }

    const tracks = await this.prisma.track.findMany({
      where: { title: { contains: q, mode: 'insensitive' } },
      take: 20,
    });

    const artists = await this.prisma.artist.findMany({
      where: { name: { contains: q, mode: 'insensitive' } },
      take: 5,
    });

    const albums = await this.prisma.album.findMany({
      where: { title: { contains: q, mode: 'insensitive' } },
      take: 5,
    });

    return { tracks, artists, albums };
  }
}
