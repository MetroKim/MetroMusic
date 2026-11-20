import { Controller, Get, NotFoundException, Param } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Controller('radio')
export class RadioController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('stations')
  async stations() {
    return this.prisma.radioStation.findMany({
      orderBy: { name: 'asc' },
    });
  }

  @Get('stations/:id')
  async station(@Param('id') id: string) {
    const station = await this.prisma.radioStation.findUnique({
      where: { id },
      include: {
        programs: { orderBy: { airsAt: 'desc' }, take: 10 },
      },
    });
    if (!station) throw new NotFoundException('STATION_NOT_FOUND');
    return station;
  }

  @Get('programs/:stationId')
  async programs(@Param('stationId') stationId: string) {
    return this.prisma.radioProgram.findMany({
      where: { stationId },
      orderBy: { airsAt: 'desc' },
      take: 20,
    });
  }
}
