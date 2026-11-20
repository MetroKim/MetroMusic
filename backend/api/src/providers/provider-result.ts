// Plan §7.3 — every adapter returns one of three explicit results.
// A fake URL or placeholder playable source is never returned.

export type ProviderResult<T> =
  | { kind: 'ok'; value: T; attribution?: string }
  | { kind: 'unsupported'; reason: string }
  | {
      kind: 'error';
      code: string;
      retryable: boolean;
      message: string;
    };

export const providerOk = <T>(value: T, attribution?: string): ProviderResult<T> => ({
  kind: 'ok',
  value,
  attribution,
});

export const providerUnsupported = <T>(reason: string): ProviderResult<T> => ({
  kind: 'unsupported',
  reason,
});

export const providerError = <T>(
  code: string,
  message: string,
  retryable = false,
): ProviderResult<T> => ({
  kind: 'error',
  code,
  retryable,
  message,
});
