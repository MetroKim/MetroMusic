import { Module } from '@nestjs/common';
import { ProvidersController } from './providers.controller';
import { ProviderRegistry } from './provider-registry.service';
import { InternalCatalogAdapter } from './internal-catalog.adapter';

@Module({
  controllers: [ProvidersController],
  providers: [ProviderRegistry, InternalCatalogAdapter],
  exports: [ProviderRegistry],
})
export class ProvidersModule {}
