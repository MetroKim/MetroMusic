import { PrismaService } from '../prisma.service';
import { CatalogService } from './catalog.service';

describe('CatalogService', () => {
  const prisma = {
    artist: { upsert: jest.fn() },
    track: {
      upsert: jest.fn(),
      findUnique: jest.fn(),
    },
    album: { findUnique: jest.fn() },
  };
  let service: CatalogService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.artist.upsert.mockResolvedValue({ id: 'artist-1' });
    prisma.track.upsert.mockResolvedValue({ id: 'track-1' });
    service = new CatalogService(prisma as unknown as PrismaService);
  });

  it('atomically converges an external track ID using an upsert', async () => {
    const dto = {
      externalId: 'bz:video-1',
      source: 'youtube',
      title: 'Nightcall',
      artistName: 'Kavinsky',
      durationSec: 254,
    };

    await expect(service.resolve(dto)).resolves.toEqual({ id: 'track-1' });

    expect(prisma.artist.upsert).toHaveBeenCalledWith({
      where: { name: 'Kavinsky' },
      create: { name: 'Kavinsky' },
      update: {},
    });
    expect(prisma.track.upsert).toHaveBeenCalledWith({
      where: { externalId: 'bz:video-1' },
      create: {
        externalId: 'bz:video-1',
        source: 'youtube',
        title: 'Nightcall',
        artistId: 'artist-1',
        duration: 254,
      },
      update: {},
    });
    expect(prisma.track.findUnique).not.toHaveBeenCalled();
  });
});
