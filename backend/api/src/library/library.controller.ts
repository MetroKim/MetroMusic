import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { LibraryService } from './library.service';

export class FavoriteDto {
  @IsString()
  trackId!: string;
}

@Controller('library')
@UseGuards(JwtAuthGuard)
export class LibraryController {
  constructor(private readonly library: LibraryService) {}

  @Get('favorites')
  listFavorites(@CurrentUser() userId: string) {
    return this.library.listFavorites(userId);
  }

  @Post('favorites')
  addFavorite(@CurrentUser() userId: string, @Body() dto: FavoriteDto) {
    return this.library.addFavorite(userId, dto.trackId);
  }

  @Delete('favorites/:trackId')
  removeFavorite(
    @CurrentUser() userId: string,
    @Param('trackId') trackId: string,
  ) {
    return this.library.removeFavorite(userId, trackId);
  }
}
