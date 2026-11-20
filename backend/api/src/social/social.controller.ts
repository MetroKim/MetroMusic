import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsUUID } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { SocialService } from './social.service';

export class FollowDto {
  @IsUUID()
  userId!: string;
}

@Controller('social')
@UseGuards(JwtAuthGuard)
export class SocialController {
  constructor(private readonly social: SocialService) {}

  @Post('follow')
  follow(@CurrentUser() userId: string, @Body() dto: FollowDto) {
    return this.social.follow(userId, dto.userId);
  }

  @Delete('follow/:userId')
  unfollow(@CurrentUser() userId: string, @Param('userId') target: string) {
    return this.social.unfollow(userId, target);
  }

  @Get('following')
  following(@CurrentUser() userId: string) {
    return this.social.listFollowing(userId);
  }

  @Get('followers')
  followers(@CurrentUser() userId: string) {
    return this.social.listFollowers(userId);
  }
}
