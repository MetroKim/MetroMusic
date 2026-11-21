import { Injectable } from '@nestjs/common';
import { MediaSigner } from './media-signer.service';

@Injectable()
export class MediaSignerFactory {
  create(): MediaSigner {
    const signingKey = process.env.MEDIA_SIGNING_KEY;
    const cdnBaseUrl = process.env.CDN_BASE_URL;

    if (process.env.NODE_ENV === 'production') {
      if (!signingKey || Buffer.byteLength(signingKey, 'utf8') < 32) {
        throw new Error('MEDIA_SIGNING_KEY_MUST_BE_AT_LEAST_32_BYTES');
      }
      if (!cdnBaseUrl) {
        throw new Error('CDN_BASE_URL_REQUIRED');
      }
      let parsedCdnUrl: URL;
      try {
        parsedCdnUrl = new URL(cdnBaseUrl);
      } catch {
        throw new Error('CDN_BASE_URL_INVALID');
      }
      if (parsedCdnUrl.protocol !== 'https:') {
        throw new Error('CDN_BASE_URL_MUST_USE_HTTPS');
      }
    }

    // Development defaults are intentionally unavailable in production.
    return new MediaSigner(
      signingKey ?? 'dev-only-signing-key',
      cdnBaseUrl ?? 'http://localhost:3000/media',
    );
  }
}
