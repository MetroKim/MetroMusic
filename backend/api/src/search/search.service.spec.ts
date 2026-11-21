import { PrismaService } from '../prisma.service';
import { SearchService } from './search.service';

describe('SearchService', () => {
  const tracks = [{ id: 'track-1', title: 'Amapiano Nights' }];
  const artists = [{ id: 'artist-1', name: 'Amapiano Collective' }];
  const albums = [{ id: 'album-1', title: 'Amapiano Sessions' }];

  const prisma = {
    track: { findMany: jest.fn() },
    artist: { findMany: jest.fn() },
    album: { findMany: jest.fn() },
  };

  let service: SearchService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.track.findMany.mockResolvedValue(tracks);
    prisma.artist.findMany.mockResolvedValue(artists);
    prisma.album.findMany.mockResolvedValue(albums);
    service = new SearchService(prisma as unknown as PrismaService);
  });

  it('returns empty result groups for queries shorter than two characters', async () => {
    await expect(service.search(' a ')).resolves.toEqual({
      tracks: [],
      artists: [],
      albums: [],
    });

    expect(prisma.track.findMany).not.toHaveBeenCalled();
    expect(prisma.artist.findMany).not.toHaveBeenCalled();
    expect(prisma.album.findMany).not.toHaveBeenCalled();
  });

  it('trims the query and searches tracks, artists and albums with bounded results', async () => {
    await expect(service.search('  Amapiano  ')).resolves.toEqual({
      tracks,
      artists,
      albums,
    });

    expect(prisma.track.findMany).toHaveBeenCalledWith({
      where: { title: { contains: 'Amapiano', mode: 'insensitive' } },
      take: 20,
    });
    expect(prisma.artist.findMany).toHaveBeenCalledWith({
      where: { name: { contains: 'Amapiano', mode: 'insensitive' } },
      take: 5,
    });
    expect(prisma.album.findMany).toHaveBeenCalledWith({
      where: { title: { contains: 'Amapiano', mode: 'insensitive' } },
      take: 5,
    });
  });
});
