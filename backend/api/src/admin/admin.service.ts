import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async dashboard() {
    const [users, tracks, albums, artists, playlists, takedowns] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.track.count(),
        this.prisma.album.count(),
        this.prisma.artist.count(),
        this.prisma.playlist.count(),
        this.prisma.contentTakedownCase.count({ where: { status: 'active' } }),
      ]);
    return {
      users,
      tracks,
      albums,
      artists,
      playlists,
      activeTakedowns: takedowns,
    };
  }

  async createUserRole(userId: string, role: string, grantedBy: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('USER_NOT_FOUND');

    const existing = await this.prisma.userRole.findUnique({
      where: { userId_role: { userId, role } },
    });
    if (existing) return { userId, role, granted: true, alreadyGranted: true };

    await this.prisma.userRole.create({
      data: { userId, role, grantedBy },
    });
    return { userId, role, granted: true, alreadyGranted: false };
  }

  async revokeUserRole(userId: string, role: string) {
    const revoked = await this.prisma.userRole.deleteMany({
      where: { userId, role },
    });
    if (revoked.count === 0) throw new NotFoundException('ROLE_NOT_FOUND');
    return { userId, role, revoked: true };
  }

  async listRoles(userId: string) {
    return this.prisma.userRole.findMany({
      where: { userId },
      select: { id: true, role: true, grantedBy: true, createdAt: true },
    });
  }

  async listTakedowns() {
    return this.prisma.contentTakedownCase.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async resolveTakedown(caseId: string) {
    const resolved = await this.prisma.contentTakedownCase.updateMany({
      where: { id: caseId },
      data: { status: 'resolved' },
    });
    if (resolved.count === 0) {
      throw new NotFoundException('CASE_NOT_FOUND');
    }
    return { resolved: true };
  }
}
