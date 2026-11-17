import { PlaybackResolveService } from '../src/playback/playback-resolve.service';
import { RightsDecisionService } from '../src/rights/rights-decision.service';
import { MediaSigner } from '../src/playback/media-signer.service';
import { PrismaService } from '../src/prisma.service';

/**
 * Playback resolve gating tests (Plan §6.7, §21.2):
 * the resolver must never hand out a source when rights deny it.
 */

const prisma = {} as unknown as PrismaService;

const signer = new MediaSigner();
const rights = new RightsDecisionService(prisma);
const service = new PlaybackResolveService(prisma, rights, signer);

describe('PlaybackResolveService.resolve', () => {
  it('rejects when rights deny streaming', async () => {
    jest
      .spyOn(rights, 'decide')
      .mockResolvedValue(
        (({
          allowed: false,
          reason: 'NO_EXPLICIT_AUTHORIZATION',
          previewOnly: false,
          qualityRestriction: null,
          expiresAt: null,
          attribution: null,
        }) as never),
      );

    await expect(
      service.resolve('user-1', {
        trackId: 't1',
        territory: 'TZ',
      }),
    ).rejects.toThrow();
  });

  it('returns a signed source when rights allow', async () => {
    jest.spyOn(rights, 'decide').mockResolvedValue(
      ({
        allowed: true,
        reason: 'OK',
        previewOnly: false,
        qualityRestriction: null,
        expiresAt: null,
        attribution: 'Provided under license',
      }) as never,
    );

    const result = await service.resolve('user-1', {
      trackId: 't1',
      territory: 'TZ',
    });

    expect(result.trackId).toBe('t1');
    expect(result.streamUrl).toBeTruthy();
    expect(result.expiresAt.getTime()).toBeGreaterThan(Date.now());
    expect(result.attribution).toBe('Provided under license');
    expect(result.previewOnly).toBe(false);
  });

  it('honors a quality restriction from the rights decision', async () => {
    jest.spyOn(rights, 'decide').mockResolvedValue(
      ({
        allowed: true,
        reason: 'OK',
        previewOnly: false,
        qualityRestriction: 'AAC_128',
        expiresAt: null,
        attribution: null,
      }) as never,
    );

    const result = await service.resolve('user-1', {
      trackId: 't1',
      territory: 'TZ',
      requestedQuality: 'LOSSLESS',
    });

    expect(result.codec).toBe('aac');
  });
});
