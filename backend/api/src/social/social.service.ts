import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class SocialService {
  constructor(private readonly prisma: PrismaService) {}

  async follow(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new NotFoundException('CANNOT_FOLLOW_SELF');
    }
    const target = await this.prisma.user.findUnique({
      where: { id: followingId },
    });
    if (!target) throw new NotFoundException('USER_NOT_FOUND');

    return this.prisma.follow.upsert({
      where: {
        followerId_followingId: { followerId, followingId },
      },
      create: { followerId, followingId },
      update: {},
    });
  }

  async unfollow(followerId: string, followingId: string) {
    await this.prisma.follow.deleteMany({
      where: { followerId, followingId },
    });
    return { unfollowed: true };
  }

  async listFollowing(userId: string) {
    const follows = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: {
        followingId: true,
        following: { select: { id: true, displayName: true } },
      },
    });
    return follows.map((f) => f.following);
  }

  async listFollowers(userId: string) {
    const follows = await this.prisma.follow.findMany({
      where: { followingId: userId },
      select: {
        followerId: true,
        follower: { select: { id: true, displayName: true } },
      },
    });
    return follows.map((f) => f.follower);
  }
}
