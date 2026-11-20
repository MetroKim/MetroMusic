import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsUUID } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PrismaService } from '../prisma.service';
import { ArtistPortalService } from './artist-portal.service';

export class ClaimDto {
  @IsUUID()
  artistId!: string;
}

@Controller('artist-portal')
@UseGuards(JwtAuthGuard)
export class ArtistPortalController {
  constructor(
    private readonly portal: ArtistPortalService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('claims')
  claim(@CurrentUser() userId: string, @Body() dto: ClaimDto) {
    return this.portal.claim(userId, dto.artistId);
  }

  @Get('claims')
  myClaims(@CurrentUser() userId: string) {
    return this.portal.myClaims(userId);
  }

  @Get('analytics')
  analytics(@CurrentUser() userId: string) {
    return this.portal.analytics(userId);
  }

  @Get('dashboard')
  async dashboard(@CurrentUser() userId: string) {
    const claims = await this.prisma.artistClaim.count({
      where: { userId },
    });
    return { activeClaims: claims };
  }
}
