import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { LyricsService } from './lyrics.service';

export class LyricsRequestDto {
  @IsString()
  trackId!: string;

  @IsString()
  territory!: string;
}

@Controller('lyrics')
@UseGuards(JwtAuthGuard)
export class LyricsController {
  constructor(private readonly lyrics: LyricsService) {}

  @Post()
  getLyrics(
    @CurrentUser() userId: string,
    @Body() dto: LyricsRequestDto,
  ) {
    return this.lyrics.getLyrics(userId, dto);
  }

  @Get('translations')
  translations(
    @Query('lyricsId') lyricsId: string,
    @Query('language') language?: string,
  ) {
    return this.lyrics.getTranslations(lyricsId ?? '', language);
  }
}
