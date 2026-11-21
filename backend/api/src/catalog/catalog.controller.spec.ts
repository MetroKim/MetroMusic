import { GUARDS_METADATA } from '@nestjs/common/constants';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CatalogService } from './catalog.service';
import { CatalogController } from './catalog.controller';

describe('CatalogController', () => {
  it('requires authentication before creating or mapping catalog tracks', () => {
    const guards = Reflect.getMetadata(
      GUARDS_METADATA,
      CatalogController.prototype.resolve,
    );

    expect(guards).toContain(JwtAuthGuard);
  });

  it('delegates catalog convergence to CatalogService', async () => {
    const track = { id: 'catalog-track-1' };
    const catalog = { resolve: jest.fn().mockResolvedValue(track) };
    const controller = new CatalogController(
      catalog as unknown as CatalogService,
    );
    const dto = {
      externalId: 'bz:video-1',
      source: 'youtube',
      title: 'Track title',
      artistName: 'Artist',
      durationSec: 180,
    };

    await expect(controller.resolve(dto)).resolves.toBe(track);
    expect(catalog.resolve).toHaveBeenCalledWith(dto);
  });
});
