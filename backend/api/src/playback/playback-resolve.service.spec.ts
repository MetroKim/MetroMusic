import { NotAcceptableException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RightsDecisionService } from '../rights/rights-decision.service';
import { MediaSigner } from './media-signer.service';
import { PlaybackResolveService } from './playback-resolve.service';

describe('PlaybackResolveService', () => {
  const rights = { decide: jest.fn() };
  const signer = { createPlaybackUrl: jest.fn() };
  let service: PlaybackResolveService;

  const request = {
    trackId: 'track-1',
    territory: 'TZ',
    requestedQuality: 'AAC_256',
  };

  beforeEach(() => {
    jest.clearAllMocks();
    service = new PlaybackResolveService(
      {} as PrismaService,
      rights as unknown as RightsDecisionService,
      signer as unknown as MediaSigner,
    );
  });

  it('never signs a full playback URL for a preview-only grant', async () => {
    rights.decide.mockResolvedValue({
      allowed: true,
      previewOnly: true,
      reason: 'OK',
      qualityRestriction: null,
      expiresAt: new Date(Date.now() + 60_000),
      attribution: 'Licensed via label',
    });

    await expect(service.resolve('user-1', request)).rejects.toBeInstanceOf(
      NotAcceptableException,
    );
    expect(signer.createPlaybackUrl).not.toHaveBeenCalled();
  });

  it('does not sign a URL when rights are denied', async () => {
    rights.decide.mockResolvedValue({
      allowed: false,
      previewOnly: false,
      reason: 'NO_EXPLICIT_AUTHORIZATION',
      qualityRestriction: null,
      expiresAt: null,
      attribution: null,
    });

    await expect(service.resolve('user-1', request)).rejects.toBeInstanceOf(
      NotAcceptableException,
    );
    expect(signer.createPlaybackUrl).not.toHaveBeenCalled();
  });

  it('signs only an explicitly authorized full-stream variant', async () => {
    rights.decide.mockResolvedValue({
      allowed: true,
      previewOnly: false,
      reason: 'OK',
      qualityRestriction: 'AAC_128',
      expiresAt: null,
      attribution: 'Licensed via label',
    });
    signer.createPlaybackUrl.mockReturnValue({
      url: 'https://cdn.example/audio/signed',
      expiresAt: new Date(Date.now() + 60_000),
    });

    await expect(service.resolve('user-1', request)).resolves.toMatchObject({
      trackId: 'track-1',
      streamUrl: 'https://cdn.example/audio/signed',
      codec: 'aac',
      attribution: 'Licensed via label',
      previewOnly: false,
    });
    expect(signer.createPlaybackUrl).toHaveBeenCalledWith('track-1', 'AAC_128', null);
  });
});
