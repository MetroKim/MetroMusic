import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RadioService } from './radio.service';

describe('RadioService', () => {
  const prisma = {
    radioStation: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    radioProgram: {
      findMany: jest.fn(),
    },
  };

  let service: RadioService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new RadioService(prisma as unknown as PrismaService);
  });

  it('lists stations without exposing stream URLs', async () => {
    const stations = [{ id: 'station-1', name: 'Breezze Live' }];
    prisma.radioStation.findMany.mockResolvedValue(stations);

    await expect(service.listStations()).resolves.toBe(stations);
    expect(prisma.radioStation.findMany).toHaveBeenCalledWith({
      select: {
        id: true,
        name: true,
        description: true,
        genre: true,
        isLive: true,
      },
      orderBy: { name: 'asc' },
    });
  });

  it('returns station details with a bounded, safe program selection', async () => {
    const station = { id: 'station-1', programs: [] };
    prisma.radioStation.findUnique.mockResolvedValue(station);

    await expect(service.getStation('station-1')).resolves.toBe(station);
    expect(prisma.radioStation.findUnique).toHaveBeenCalledWith({
      where: { id: 'station-1' },
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
  });

  it('throws a stable not-found error for unknown stations', async () => {
    prisma.radioStation.findUnique.mockResolvedValue(null);

    await expect(service.getStation('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('returns a bounded program list for a station', async () => {
    prisma.radioProgram.findMany.mockResolvedValue([]);

    await expect(service.programsForStation('station-1')).resolves.toEqual([]);
    expect(prisma.radioProgram.findMany).toHaveBeenCalledWith({
      where: { stationId: 'station-1' },
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
  });
});
