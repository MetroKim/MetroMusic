import { RightsDecisionService } from '../src/rights/rights-decision.service';
import { PrismaService } from '../src/prisma.service';

/**
 * Rights decision matrix tests (Plan §9.1, §21.2).
 *
 * Deny-by-default is the core security property of the platform:
 * a protected action must never pass without an explicit
 * authorization row, an open territory, and no active takedown.
 */

const prisma = {
  territoryAvailability: { findFirst: jest.fn() },
  contentTakedownCase: { findFirst: jest.fn() },
  rightsUsagePermission: { findFirst: jest.fn() },
  providerAttribution: { findFirst: jest.fn() },
} as unknown as PrismaService;

const service = new RightsDecisionService(prisma);
const now = new Date();

beforeEach(() => {
  jest.resetAllMocks();
});

describe('RightsDecisionService.decide', () => {
  it('denies when the territory is not open', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue(
      null,
    );

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(false);
    expect(d.reason).toBe('NOT_AVAILABLE_IN_TERRITORY');
  });

  it('denies when an active takedown exists', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue({
      id: 'case1',
      status: 'active',
    });

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(false);
    expect(d.reason).toBe('TAKEDOWN_ACTIVE');
  });

  it('allows metadata.display without explicit permission', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue(
      null,
    );
    (prisma.rightsUsagePermission.findFirst as jest.Mock).mockResolvedValue(
      null,
    );

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'metadata.display',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(true);
    expect(d.previewOnly).toBe(false);
  });

  it('falls back to preview-only when only a preview permission exists', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue(
      null,
    );
    (prisma.rightsUsagePermission.findFirst as jest.Mock)
      .mockResolvedValueOnce(null) // stream.full
      .mockResolvedValueOnce({ id: 'p1', action: 'preview' });

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(true);
    expect(d.previewOnly).toBe(true);
  });

  it('denies protected actions with no explicit authorization (deny-by-default)', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue(
      null,
    );
    (prisma.rightsUsagePermission.findFirst as jest.Mock)
      .mockResolvedValueOnce(null) // stream.full
      .mockResolvedValueOnce(null); // preview

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(false);
    expect(d.reason).toBe('NO_EXPLICIT_AUTHORIZATION');
  });

  it('denies when the rights window has not opened yet', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue(
      null,
    );
    (prisma.rightsUsagePermission.findFirst as jest.Mock).mockResolvedValue({
      id: 'p1',
      action: 'stream.full',
      startAt: new Date(now.getTime() + 86_400_000),
      endAt: null,
    });

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(false);
    expect(d.reason).toBe('RIGHTS_WINDOW_NOT_OPEN');
  });

  it('denies when the rights window has expired', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue(
      null,
    );
    (prisma.rightsUsagePermission.findFirst as jest.Mock).mockResolvedValue({
      id: 'p1',
      action: 'stream.full',
      startAt: null,
      endAt: new Date(now.getTime() - 86_400_000),
    });

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(false);
    expect(d.reason).toBe('RIGHTS_EXPIRED');
  });

  it('allows with attribution when a valid permission exists', async () => {
    (prisma.territoryAvailability.findFirst as jest.Mock).mockResolvedValue({
      id: 'av1',
    });
    (prisma.contentTakedownCase.findFirst as jest.Mock).mockResolvedValue(
      null,
    );
    (prisma.rightsUsagePermission.findFirst as jest.Mock).mockResolvedValue({
      id: 'p1',
      action: 'stream.full',
      startAt: null,
      endAt: null,
    });
    (prisma.providerAttribution.findFirst as jest.Mock).mockResolvedValue({
      text: 'Provided under license',
    });

    const d = await service.decide({
      userId: 'u1',
      trackId: 't1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(d.allowed).toBe(true);
    expect(d.reason).toBe('OK');
    expect(d.attribution).toBe('Provided under license');
  });
});
