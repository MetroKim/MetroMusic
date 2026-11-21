import { MediaSignerFactory } from './media-signer.factory';

describe('MediaSignerFactory', () => {
  const originalNodeEnv = process.env.NODE_ENV;
  const originalKey = process.env.MEDIA_SIGNING_KEY;
  const originalCdn = process.env.CDN_BASE_URL;

  afterEach(() => {
    if (originalNodeEnv === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = originalNodeEnv;
    if (originalKey === undefined) delete process.env.MEDIA_SIGNING_KEY;
    else process.env.MEDIA_SIGNING_KEY = originalKey;
    if (originalCdn === undefined) delete process.env.CDN_BASE_URL;
    else process.env.CDN_BASE_URL = originalCdn;
  });

  it('rejects a missing production signing key', () => {
    process.env.NODE_ENV = 'production';
    delete process.env.MEDIA_SIGNING_KEY;
    process.env.CDN_BASE_URL = 'https://cdn.example';

    expect(() => new MediaSignerFactory().create()).toThrow(
      'MEDIA_SIGNING_KEY_MUST_BE_AT_LEAST_32_BYTES',
    );
  });

  it('rejects a short production signing key', () => {
    process.env.NODE_ENV = 'production';
    process.env.MEDIA_SIGNING_KEY = 'too-short';
    process.env.CDN_BASE_URL = 'https://cdn.example';

    expect(() => new MediaSignerFactory().create()).toThrow(
      'MEDIA_SIGNING_KEY_MUST_BE_AT_LEAST_32_BYTES',
    );
  });

  it('rejects non-HTTPS production CDN URLs', () => {
    process.env.NODE_ENV = 'production';
    process.env.MEDIA_SIGNING_KEY = 'x'.repeat(40);
    process.env.CDN_BASE_URL = 'http://cdn.example';

    expect(() => new MediaSignerFactory().create()).toThrow(
      'CDN_BASE_URL_MUST_USE_HTTPS',
    );
  });
});
