import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class LibraryService {
  constructor(private readonly prisma: PrismaService) {}

  async listFavorites(userId: string) {
    return this.prisma.favorite.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { id: true, trackId: true, createdAt: true },
    });
  }

  async addFavorite(userId: string, trackId: string) {
    return this.prisma.favorite.upsert({
      where: { userId_trackId: { userId, trackId } },
      create: { userId, trackId },
      update: {},
    });
  }

  async removeFavorite(userId: string, trackId: string) {
    await this.prisma.favorite.deleteMany({
      where: { userId, trackId },
    });
    return { removed: true };
  }
}
