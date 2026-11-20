import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { PrismaModule } from './prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CatalogModule } from './catalog/catalog.module';
import { RightsModule } from './rights/rights.module';
import { PlaybackModule } from './playback/playback.module';
import { LibraryModule } from './library/library.module';
import { SearchModule } from './search/search.module';
import { PlaylistsModule } from './playlists/playlists.module';
import { DownloadsModule } from './downloads/downloads.module';
import { HomeModule } from './home/home.module';
import { LyricsModule } from './lyrics/lyrics.module';
import { RadioModule } from './radio/radio.module';
import { RecommendationsModule } from './recommendations/recommendations.module';
import { OnboardingModule } from './onboarding/onboarding.module';
import { ReplayModule } from './replay/replay.module';
import { SocialModule } from './social/social.module';
import { ClassicalModule } from './classical/classical.module';
import { AdminModule } from './admin/admin.module';
import { ProvidersModule } from './providers/providers.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ModerationModule } from './moderation/moderation.module';
import { ArtistPortalModule } from './artist_portal/artist-portal.module';
import { DistributorModule } from './distributor/distributor.module';
import { MediaModule } from './media/media.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
    PrismaModule,
    AuthModule,
    UsersModule,
    CatalogModule,
    RightsModule,
    PlaybackModule,
    LibraryModule,
    SearchModule,
    PlaylistsModule,
    DownloadsModule,
    HomeModule,
    LyricsModule,
    RadioModule,
    RecommendationsModule,
    OnboardingModule,
    ReplayModule,
    SocialModule,
    ClassicalModule,
    AdminModule,
    ProvidersModule,
    NotificationsModule,
    ModerationModule,
    ArtistPortalModule,
    DistributorModule,
    MediaModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
