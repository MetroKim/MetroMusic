import { Module } from '@nestjs/common';
import { ArtistPortalController } from './artist-portal.controller';
import { ArtistPortalService } from './artist-portal.service';

@Module({
  controllers: [ArtistPortalController],
  providers: [ArtistPortalService],
  exports: [ArtistPortalService],
})
export class ArtistPortalModule {}
