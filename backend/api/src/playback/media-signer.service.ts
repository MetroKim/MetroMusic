import { createHmac, timingSafeEqual } from 'crypto';

export class MediaSigner {
  constructor(
    private readonly signingKey: string,
    private readonly cdnBaseUrl: string,
  ) {}

  private sign(payload: string): string {
    return createHmac('sha256', this.signingKey)
      .update(payload)
      .digest('base64url');
  }

  createPlaybackUrl(
    trackId: string,
    variant: string,
    rightsExpiresAt: Date | null = null,
  ): { url: string; expiresAt: Date } {
    const now = Date.now();
    const defaultExpiry = now + 6 * 3600 * 1000;
    const expires = Math.min(
      defaultExpiry,
      rightsExpiresAt?.getTime() ?? defaultExpiry,
    );
    if (expires <= now) {
      throw new Error('MEDIA_URL_EXPIRY_INVALID');
    }
    const signature = this.sign(`${trackId}:${variant}:${expires}`);
    return {
      url: `${this.cdnBaseUrl}/audio/${trackId}/${variant}?e=${expires}&s=${signature}`,
      expiresAt: new Date(expires),
    };
  }

  signPlaybackUrl(
    trackId: string,
    variant: string,
    rightsExpiresAt: Date | null = null,
  ): string {
    return this.createPlaybackUrl(trackId, variant, rightsExpiresAt).url;
  }

  verify(trackId: string, variant: string, expires: number, sig: string): boolean {
    if (Date.now() >= expires) return false;
    const expected = Buffer.from(
      this.sign(`${trackId}:${variant}:${expires}`),
      'utf8',
    );
    const actual = Buffer.from(sig, 'utf8');
    if (actual.length !== expected.length) return false;
    return timingSafeEqual(expected, actual);
  }
}
