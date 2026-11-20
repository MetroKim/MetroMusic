import { Injectable } from '@nestjs/common';
import { MediaSigner } from './media-signer.service';

@Injectable()
export class MediaSignerFactory {
  create(): MediaSigner {
    return new MediaSigner(
      process.env.MEDIA_SIGNING_KEY ?? 'dev-only-signing-key',
      process.env.CDN_BASE_URL ?? 'http://localhost:3000/media',
    );
  }
}
