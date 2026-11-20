import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class ClassicalService {
  constructor(private readonly prisma: PrismaService) {}

  async composers() {
    return this.prisma.composer.findMany({
      orderBy: { name: 'asc' },
      include: { _count: { select: { works: true } } },
    });
  }

  async composer(id: string) {
    const composer = await this.prisma.composer.findUnique({
      where: { id },
      include: {
        works: { orderBy: { title: 'asc' }, include: { _count: { select: { movements: true } } } },
      },
    });
    if (!composer) throw new NotFoundException('COMPOSER_NOT_FOUND');
    return composer;
  }

  async work(id: string) {
    const work = await this.prisma.classicalWork.findUnique({
      where: { id },
      include: {
        composer: true,
        movements: { orderBy: { position: 'asc' } },
      },
    });
    if (!work) throw new NotFoundException('WORK_NOT_FOUND');
    return work;
  }
}
