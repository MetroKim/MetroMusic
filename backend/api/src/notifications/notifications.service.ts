import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Plan §13.2 — templates, delivery (stub now, real push later),
// device tokens, history.
@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async registerToken(userId: string, token: string, platform: string) {
    return this.prisma.pushToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId },
    });
  }

  async listForUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async create(
    userId: string,
    dto: { title: string; body: string; kind?: string },
  ) {
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title: dto.title,
        body: dto.body,
        kind: dto.kind ?? 'general',
      },
    });
    // Delivery to FCM/APNs lands with the workers phase; the record
    // exists now so the history UI can be built against real data.
    return notification;
  }

  async markRead(userId: string, notificationId: string) {
    await this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { readAt: new Date() },
    });
    return { read: true };
  }
}
