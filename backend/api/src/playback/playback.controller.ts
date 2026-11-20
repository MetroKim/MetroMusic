import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsIn, IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PlaybackResolveService } from './playback-resolve.service';

export class ResolveDto {
  @IsString()
  trackId!: string;

  @IsString()
  territory!: string;

  @IsOptional()
  @IsIn(['AAC_128', 'AAC_256', 'LOSSLESS', 'HI_RES'])
  requestedQuality?: string;
}

@Controller('playback')
export class PlaybackController {
  constructor(private readonly resolver: PlaybackResolveService) {}

  @Post('resolve')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  resolve(@CurrentUser() userId: string, @Body() dto: ResolveDto) {
    return this.resolver.resolve(userId, dto);
  }
}
