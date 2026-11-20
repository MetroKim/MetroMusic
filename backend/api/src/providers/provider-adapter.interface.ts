import { ProviderResult } from './provider-result';

// Plan §7.2 — a provider must declare its identity, capabilities, and
// the metadata operations it supports. Playback resolution is only
// implemented by providers that explicitly authorize it.
export interface ProviderCapabilities {
  search: boolean;
  metadata: boolean;
  availability: boolean;
  playback: boolean;
  download: boolean;
}

export interface ProviderTrack {
  providerTrackId: string;
  title: string;
  artist: string;
  artworkUrl?: string;
  durationSec?: number;
}

export interface ProviderAdapter {
  readonly providerId: string;
  readonly capabilities: ProviderCapabilities;

  search(query: string): Promise<ProviderResult<ProviderTrack[]>>;

  getTrack(providerTrackId: string): Promise<ProviderResult<ProviderTrack>>;

  getAvailability(
    providerTrackId: string,
    territory: string,
  ): Promise<ProviderResult<{ available: boolean }>>;
}
