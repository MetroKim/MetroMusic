import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { HomeService } from './home.service';

export class RecordPlayDto {
  @IsString()
  trackId!: string;
}

@Controller('home')
@UseGuards(JwtAuthGuard)
export class HomeController {
  constructor(private readonly home: HomeService) {}

  @Get()
  feed(@CurrentUser() userId: string) {
    return this.home.feed(userId);
  }

  @Post('plays')
  recordPlay(
    @CurrentUser() userId: string,
    @Body() dto: RecordPlayDto,
  ) {
    return this.home.recordPlay(userId, dto.trackId);
  }
}
