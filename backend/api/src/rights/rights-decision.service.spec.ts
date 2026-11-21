import { PrismaService } from '../prisma.service';
import { RightsDecisionService } from './rights-decision.service';

describe('RightsDecisionService', () => {
  let fullPermission: any;
  let previewPermission: any;
  const prisma = {
    territoryAvailability: { findFirst: jest.fn() },
    contentTakedownCase: { findFirst: jest.fn() },
    rightsUsagePermission: { findFirst: jest.fn() },
    providerAttribution: { findFirst: jest.fn() },
  };
  let service: RightsDecisionService;

  beforeEach(() => {
    jest.clearAllMocks();
    fullPermission = null;
    previewPermission = null;
    prisma.territoryAvailability.findFirst.mockResolvedValue({ id: 'territory-1' });
    prisma.contentTakedownCase.findFirst.mockResolvedValue(null);
    prisma.rightsUsagePermission.findFirst.mockImplementation(
      ({ where }: { where: { action: string } }) =>
        Promise.resolve(
          where.action === 'preview' ? previewPermission : fullPermission,
        ),
    );
    prisma.providerAttribution.findFirst.mockResolvedValue({ text: 'Licensed via label' });
    service = new RightsDecisionService(prisma as unknown as PrismaService);
  });

  it('denies tracks unavailable in the requested territory', async () => {
    prisma.territoryAvailability.findFirst.mockResolvedValue(null);

    const decision = await service.decide({
      userId: 'user-1',
      trackId: 'track-1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(decision.allowed).toBe(false);
    expect(decision.reason).toBe('NOT_AVAILABLE_IN_TERRITORY');
  });

  it('denies active takedowns before checking stream permission', async () => {
    prisma.contentTakedownCase.findFirst.mockResolvedValue({ id: 'case-1' });

    const decision = await service.decide({
      userId: 'user-1',
      trackId: 'track-1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(decision.allowed).toBe(false);
    expect(decision.reason).toBe('TAKEDOWN_ACTIVE');
    expect(prisma.rightsUsagePermission.findFirst).not.toHaveBeenCalled();
  });

  it('does not accept a preview grant before its start time', async () => {
    previewPermission = {
      startAt: new Date(Date.now() + 60_000),
      endAt: null,
    };

    const decision = await service.decide({
      userId: 'user-1',
      trackId: 'track-1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(decision.allowed).toBe(false);
    expect(decision.reason).toBe('RIGHTS_WINDOW_NOT_OPEN');
  });

  it('does not accept an expired preview grant', async () => {
    previewPermission = {
      startAt: null,
      endAt: new Date(Date.now() - 60_000),
    };

    const decision = await service.decide({
      userId: 'user-1',
      trackId: 'track-1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(decision.allowed).toBe(false);
    expect(decision.reason).toBe('RIGHTS_EXPIRED');
  });

  it('does not use preview permission to authorize a download', async () => {
    previewPermission = {
      startAt: null,
      endAt: new Date(Date.now() + 60_000),
    };

    const decision = await service.decide({
      userId: 'user-1',
      trackId: 'track-1',
      action: 'download',
      territory: 'TZ',
    });

    expect(decision.allowed).toBe(false);
    expect(decision.reason).toBe('NO_EXPLICIT_AUTHORIZATION');
    expect(prisma.rightsUsagePermission.findFirst).toHaveBeenCalledTimes(1);
  });

  it('returns a bounded preview-only decision for an active preview grant', async () => {
    const endAt = new Date(Date.now() + 60_000);
    previewPermission = { startAt: new Date(Date.now() - 60_000), endAt };

    const decision = await service.decide({
      userId: 'user-1',
      trackId: 'track-1',
      action: 'stream.full',
      territory: 'TZ',
    });

    expect(decision).toMatchObject({
      allowed: true,
      previewOnly: true,
      expiresAt: endAt,
      attribution: 'Licensed via label',
    });
  });
});
