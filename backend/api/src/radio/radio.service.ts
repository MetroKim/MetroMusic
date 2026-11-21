import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class RadioService {
  constructor(private readonly prisma: PrismaService) {}

  async listStations() {
    // Stream URLs are deliberately not part of the public directory DTO.
    // A future playback-session endpoint must authorize and resolve streams.
    return this.prisma.radioStation.findMany({
      select: {
        id: true,
        name: true,
        description: true,
        genre: true,
        isLive: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  async getStation(stationId: string) {
    const station = await this.prisma.radioStation.findUnique({
      where: { id: stationId },
      select: {
        id: true,
        name: true,
        description: true,
        genre: true,
        isLive: true,
        programs: {
          select: {
            id: true,
            title: true,
            presenter: true,
            airsAt: true,
            durationMin: true,
          },
          orderBy: { airsAt: 'desc' },
          take: 10,
        },
      },
    });
    if (!station) throw new NotFoundException('STATION_NOT_FOUND');
    return station;
  }

  async programsForStation(stationId: string) {
    return this.prisma.radioProgram.findMany({
      where: { stationId },
      select: {
        id: true,
        stationId: true,
        title: true,
        presenter: true,
        airsAt: true,
        durationMin: true,
      },
      orderBy: { airsAt: 'desc' },
      take: 20,
    });
  }
}
