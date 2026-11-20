import {
  Body,
  Controller,
  Get,
  Param,
  Post,
} from '@nestjs/common';
import { IsInt, IsString, Min, MinLength } from 'class-validator';
import { CatalogService } from './catalog.service';

export class ResolveTrackDto {
  @IsString()
  @MinLength(1)
  externalId!: string;

  @IsString()
  @MinLength(1)
  source!: string;

  @IsString()
  @MinLength(1)
  title!: string;

  @IsString()
  @MinLength(1)
  artistName!: string;

  @IsInt()
  @Min(1)
  durationSec!: number;
}

@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  // ID convergence: external track → one canonical catalog row.
  @Post('resolve')
  resolve(@Body() dto: ResolveTrackDto) {
    return this.catalog.resolve(dto);
  }

  @Get('songs/:id')
  song(@Param('id') id: string) {
    return this.catalog.song(id);
  }

  @Get('albums/:id')
  album(@Param('id') id: string) {
    return this.catalog.album(id);
  }

  @Get('artists/:id')
  artist(@Param('id') id: string) {
    return this.catalog.artist(id);
  }
}
