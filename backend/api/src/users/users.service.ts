import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async profile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('USER_NOT_FOUND');
    return user;
  }

  async update(userId: string, body: Record<string, unknown>) {
    const data: { displayName?: string } = {};
    const name = body['displayName'];
    if (typeof name === 'string') {
      data.displayName = name;
    }
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data,
    });
    return { id: updated.id, displayName: updated.displayName };
  }

  async delete(userId: string) {
    await this.prisma.user.delete({ where: { id: userId } });
    return { deleted: true };
  }
}
