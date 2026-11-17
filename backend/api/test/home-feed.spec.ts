import { HomeService } from '../src/home/home.service';
import { PrismaService } from '../src/prisma.service';

/**
 * Home rail tests (Plan §5.5): the Recently Played rail keeps one
 * entry per track, most-recent play first, capped at 12 — backed by
 * a per-play history table.
 */

const prisma = {
  recentlyPlayed: { findMany: jest.fn(), create: jest.fn() },
  favorite: { findMany: jest.fn() },
  listeningEvent: { create: jest.fn() },
} as unknown as PrismaService;

const service = new HomeService(prisma);

beforeEach(() => {
  jest.resetAllMocks();
});

describe('HomeService.feed', () => {
  it('dedups repeated plays and keeps the latest order', async () => {
    (prisma.recentlyPlayed.findMany as jest.Mock).mockResolvedValue([
      { trackId: 'a' },
      { trackId: 'b' },
      { trackId: 'a' },
      { trackId: 'c' },
    ]);
    (prisma.favorite.findMany as jest.Mock).mockResolvedValue([
      { trackId: 'f1' },
    ]);

    const sections = await service.feed('u1');

    expect(sections[0].sectionType).toBe('recently_played');
    expect(sections[0].trackIds).toEqual(['a', 'b', 'c']);
    expect(sections[1].sectionType).toBe('favorites');
    expect(sections[1].trackIds).toEqual(['f1']);
  });

  it('caps the rail at 12 unique tracks', async () => {
    const rows = Array.from({ length: 30 }, (_, i) => ({
      trackId: `t${i % 20}`,
    }));
    (prisma.recentlyPlayed.findMany as jest.Mock).mockResolvedValue(rows);
    (prisma.favorite.findMany as jest.Mock).mockResolvedValue([]);

    const sections = await service.feed('u1');

    expect(sections).toHaveLength(1);
    expect(sections[0].trackIds).toHaveLength(12);
    expect(new Set(sections[0].trackIds).size).toBe(12);
  });

  it('omits sections when the user has no history or favorites', async () => {
    (prisma.recentlyPlayed.findMany as jest.Mock).mockResolvedValue([]);
    (prisma.favorite.findMany as jest.Mock).mockResolvedValue([]);

    const sections = await service.feed('u1');

    expect(sections).toHaveLength(0);
  });
});

describe('HomeService.recordPlay', () => {
  it('appends a new history row per play (no upsert)', async () => {
    (prisma.recentlyPlayed.create as jest.Mock).mockResolvedValue({});
    (prisma.listeningEvent.create as jest.Mock).mockResolvedValue({});

    await service.recordPlay('u1', 'a');

    expect(prisma.recentlyPlayed.create).toHaveBeenCalledWith({
      data: { userId: 'u1', trackId: 'a' },
    });
    expect(prisma.listeningEvent.create).toHaveBeenCalledWith({
      data: { userId: 'u1', trackId: 'a' },
    });
  });
});
