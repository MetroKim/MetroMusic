import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Convergence seam (plan §7.4): the client plays external-source
// tracks (e.g. YouTube). resolve() gives each externalId exactly one
// canonical catalog Track row — created once, reused forever, so
// favorites/plays synced from the app reference real catalog IDs.
@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  async resolve(dto: {
    externalId: string;
    source: string;
    title: string;
    artistName: string;
    durationSec: number;
  }) {
    // 1. Existing mapping? Return it.
    const existing = await this.prisma.track.findUnique({
      where: { externalId: dto.externalId },
    });
    if (existing) return existing;

    // 2. Create the mapping: artist upserted by unique name, then
    // the track row keyed on externalId.
    const artist = await this.prisma.artist.upsert({
      where: { name: dto.artistName },
      create: { name: dto.artistName },
      update: {},
    });

    return this.prisma.track.create({
      data: {
        externalId: dto.externalId,
        source: dto.source,
        title: dto.title,
        artistId: artist.id,
        duration: Math.round(dto.durationSec),
      },
    });
  }

  async song(id: string) {
    const track = await this.prisma.track.findUnique({
      where: { id },
      include: { artist: true, album: true },
    });
    if (!track) throw new NotFoundException('TRACK_NOT_FOUND');
    return track;
  }

  async album(id: string) {
    const album = await this.prisma.album.findUnique({
      where: { id },
      include: { tracks: true, artist: true },
    });
    if (!album) throw new NotFoundException('ALBUM_NOT_FOUND');
    return album;
  }

  async artist(id: string) {
    const artist = await this.prisma.artist.findUnique({
      where: { id },
      include: { albums: true, tracks: true },
    });
    if (!artist) throw new NotFoundException('ARTIST_NOT_FOUND');
    return artist;
  }
}
