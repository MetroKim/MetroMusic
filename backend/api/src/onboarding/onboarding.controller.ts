import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsArray, IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { OnboardingService } from './onboarding.service';

export class SavePreferencesDto {
  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @IsString()
  language?: string;

  @IsOptional()
  @IsArray()
  genres?: string[];

  @IsOptional()
  @IsArray()
  favoriteArtists?: string[];
}

@Controller('onboarding')
@UseGuards(JwtAuthGuard)
export class OnboardingController {
  constructor(private readonly onboarding: OnboardingService) {}

  @Post('preferences')
  save(
    @CurrentUser() userId: string,
    @Body() dto: SavePreferencesDto,
  ) {
    return this.onboarding.savePreferences(userId, dto);
  }

  @Get('preferences')
  get(@CurrentUser() userId: string) {
    return this.onboarding.getPreferences(userId);
  }
}
