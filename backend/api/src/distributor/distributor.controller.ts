import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsArray, IsString, MinLength } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { DistributorService } from './distributor.service';

export class SubmitReleaseDto {
  @IsString()
  @MinLength(1)
  title!: string;

  @IsString()
  @MinLength(1)
  artistName!: string;

  @IsArray()
  trackTitles!: string[];
}

@Controller('distributor')
@UseGuards(JwtAuthGuard)
export class DistributorController {
  constructor(private readonly distributor: DistributorService) {}

  @Post('releases')
  submit(@CurrentUser() userId: string, @Body() dto: SubmitReleaseDto) {
    return this.distributor.submitRelease(userId, dto);
  }

  @Get('releases')
  mySubmissions(@CurrentUser() userId: string) {
    return this.distributor.mySubmissions(userId);
  }

  @Post('releases/:id/validate')
  validate(@Param('id') id: string) {
    return this.distributor.validate(id);
  }
}
