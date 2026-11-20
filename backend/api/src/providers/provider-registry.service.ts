import { Injectable } from '@nestjs/common';
import { InternalCatalogAdapter } from './internal-catalog.adapter';
import { ProviderAdapter } from './provider-adapter.interface';

// Plan §7.5 — the registry owns provider identity, capability
// declaration, and health. Adapters are registered with explicit
// capability flags; playback is only ever declared by providers that
// authorize it in writing.
@Injectable()
export class ProviderRegistry {
  private readonly adapters = new Map<string, ProviderAdapter>();

  constructor(internal: InternalCatalogAdapter) {
    this.register(internal);
  }

  register(adapter: ProviderAdapter) {
    this.adapters.set(adapter.providerId, adapter);
  }

  get(providerId: string): ProviderAdapter | undefined {
    return this.adapters.get(providerId);
  }

  list(): { providerId: string; capabilities: ProviderAdapter['capabilities'] }[] {
    return [...this.adapters.values()].map((a) => ({
      providerId: a.providerId,
      capabilities: a.capabilities,
    }));
  }
}
