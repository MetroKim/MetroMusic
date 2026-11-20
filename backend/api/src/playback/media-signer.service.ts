import { createHmac } from 'crypto';

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

  signPlaybackUrl(trackId: string, variant: string): string {
    const expires = Date.now() + 6 * 3600 * 1000;
    const signature = this.sign(`${trackId}:${variant}:${expires}`);
    return `${this.cdnBaseUrl}/audio/${trackId}/${variant}?e=${expires}&s=${signature}`;
  }

  verify(trackId: string, variant: string, expires: number, sig: string): boolean {
    if (Date.now() > expires) return false;
    return this.sign(`${trackId}:${variant}:${expires}`) === sig;
  }
}
