import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  me(@CurrentUser() userId: string) {
    return this.users.profile(userId);
  }

  @Patch('me')
  patchMe(
    @CurrentUser() userId: string,
    @Body() body: Record<string, unknown>,
  ) {
    return this.users.update(userId, body);
  }

  @Delete('me')
  deleteMe(@CurrentUser() userId: string) {
    return this.users.delete(userId);
  }
}
