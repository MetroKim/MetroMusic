import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class PlaylistsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, name: string) {
    return this.prisma.playlist.create({
      data: { userId, name },
    });
  }

  async list(userId: string) {
    return this.prisma.playlist.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async get(userId: string, playlistId: string) {
    const playlist = await this.prisma.playlist.findFirst({
      where: { id: playlistId, userId },
      include: { items: { orderBy: { position: 'asc' } } },
    });
    if (!playlist) throw new NotFoundException('PLAYLIST_NOT_FOUND');
    return playlist;
  }

  async addTrack(userId: string, playlistId: string, trackId: string) {
    await this.assertOwned(userId, playlistId);
    const count = await this.prisma.playlistItem.count({
      where: { playlistId },
    });
    return this.prisma.playlistItem.create({
      data: { playlistId, trackId, position: count },
    });
  }

  async removeTrack(userId: string, playlistId: string, trackId: string) {
    await this.assertOwned(userId, playlistId);
    await this.prisma.playlistItem.deleteMany({
      where: { playlistId, trackId },
    });
    return { removed: true };
  }

  private async assertOwned(userId: string, playlistId: string) {
    const owned = await this.prisma.playlist.findFirst({
      where: { id: playlistId, userId },
    });
    if (!owned) throw new NotFoundException('PLAYLIST_NOT_FOUND');
  }
}
