import { Module } from '@nestjs/common';
import { RightsModule } from '../rights/rights.module';
import { PlaybackResolveService } from './playback-resolve.service';
import { PlaybackController } from './playback.controller';
import { MediaSigner } from './media-signer.service';
import { MediaSignerFactory } from './media-signer.factory';

@Module({
  imports: [RightsModule],
  controllers: [PlaybackController],
  providers: [
    PlaybackResolveService,
    MediaSignerFactory,
    {
      provide: MediaSigner,
      useFactory: (factory: MediaSignerFactory) => factory.create(),
      inject: [MediaSignerFactory],
    },
  ],
})
export class PlaybackModule {}
