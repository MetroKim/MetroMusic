import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsIn, IsString, MaxLength } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ModerationService } from './moderation.service';

export class FileReportDto {
  @IsIn(['track', 'playlist', 'user', 'comment'])
  targetType!: string;

  @IsString()
  targetId!: string;

  @IsString()
  @MaxLength(500)
  reason!: string;
}

export class ResolveDto {
  @IsIn(['dismissed', 'actioned'])
  resolution!: string;
}

@Controller('moderation')
@UseGuards(JwtAuthGuard)
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Post('reports')
  file(@CurrentUser() userId: string, @Body() dto: FileReportDto) {
    return this.moderation.fileReport(userId, dto);
  }

  @Get('reports')
  listOpen() {
    return this.moderation.listOpen();
  }

  @Post('reports/:id/resolve')
  resolve(
    @Param('id') id: string,
    @Body() dto: ResolveDto,
  ) {
    return this.moderation.resolve(
      id,
      dto.resolution as 'dismissed' | 'actioned',
    );
  }
}
