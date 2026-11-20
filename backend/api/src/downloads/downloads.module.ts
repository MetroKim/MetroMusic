import { Module } from '@nestjs/common';
import { RightsModule } from '../rights/rights.module';
import { DownloadsController } from './downloads.controller';
import { DownloadsService } from './downloads.service';
import { MediaSigner } from '../playback/media-signer.service';
import { MediaSignerFactory } from '../playback/media-signer.factory';

@Module({
  imports: [RightsModule],
  controllers: [DownloadsController],
  providers: [
    DownloadsService,
    MediaSignerFactory,
    {
      provide: MediaSigner,
      useFactory: (factory: MediaSignerFactory) => factory.create(),
      inject: [MediaSignerFactory],
    },
  ],
})
export class DownloadsModule {}
