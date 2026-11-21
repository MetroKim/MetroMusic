import { PrismaService } from '../prisma.service';
import { RightsDecisionService } from '../rights/rights-decision.service';
import { MediaSigner } from '../playback/media-signer.service';
import { DownloadsService } from './downloads.service';

describe('DownloadsService', () => {
  const prisma = { downloadRecord: { upsert: jest.fn() } };
  const rights = { decide: jest.fn() };
  const signer = { createPlaybackUrl: jest.fn() };
  let service: DownloadsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new DownloadsService(
      prisma as unknown as PrismaService,
      rights as unknown as RightsDecisionService,
      signer as unknown as MediaSigner,
    );
  });

  it('does not create a download for a preview-only decision', async () => {
    rights.decide.mockResolvedValue({
      allowed: true,
      previewOnly: true,
      reason: 'OK',
      qualityRestriction: null,
      expiresAt: null,
      attribution: null,
    });

    await expect(
      service.authorizeAndRecord('user-1', {
        trackId: 'track-1',
        territory: 'TZ',
      }),
    ).resolves.toEqual({
      allowed: false,
      reason: 'PREVIEW_ONLY',
      url: null,
    });

    expect(prisma.downloadRecord.upsert).not.toHaveBeenCalled();
    expect(signer.createPlaybackUrl).not.toHaveBeenCalled();
  });

  it('records and signs a download only after explicit authorization', async () => {
    rights.decide.mockResolvedValue({
      allowed: true,
      previewOnly: false,
      reason: 'OK',
      qualityRestriction: null,
      expiresAt: null,
      attribution: 'Licensed via label',
    });
    prisma.downloadRecord.upsert.mockResolvedValue({ id: 'download-1' });
    signer.createPlaybackUrl.mockReturnValue({
      url: 'https://cdn.example/download',
      expiresAt: new Date(Date.now() + 60_000),
    });

    await expect(
      service.authorizeAndRecord('user-1', {
        trackId: 'track-1',
        territory: 'TZ',
      }),
    ).resolves.toMatchObject({
      allowed: true,
      url: 'https://cdn.example/download',
      recordId: 'download-1',
    });

    expect(signer.createPlaybackUrl).toHaveBeenCalledWith('track-1', 'download', null);
  });
});
