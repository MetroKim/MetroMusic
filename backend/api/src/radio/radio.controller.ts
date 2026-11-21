import { Controller, Get, Param } from '@nestjs/common';
import { RadioService } from './radio.service';

@Controller('radio')
export class RadioController {
  constructor(private readonly radio: RadioService) {}

  @Get('stations')
  stations() {
    return this.radio.listStations();
  }

  @Get('stations/:id')
  station(@Param('id') id: string) {
    return this.radio.getStation(id);
  }

  @Get('programs/:stationId')
  programs(@Param('stationId') stationId: string) {
    return this.radio.programsForStation(stationId);
  }
}
