import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class RadioService {
  constructor(private readonly prisma: PrismaService) {}

  async listStations() {
    return this.prisma.radioStation.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async getStation(stationId: string) {
    const station = await this.prisma.radioStation.findUnique({
      where: { id: stationId },
      include: {
        programs: {
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
      orderBy: { airsAt: 'desc' },
      take: 20,
    });
  }
}
