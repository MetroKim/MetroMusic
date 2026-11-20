import { Controller, Get, Param } from '@nestjs/common';
import { ClassicalService } from './classical.service';

@Controller('classical')
export class ClassicalController {
  constructor(private readonly classical: ClassicalService) {}

  @Get('composers')
  composers() {
    return this.classical.composers();
  }

  @Get('composers/:id')
  composer(@Param('id') id: string) {
    return this.classical.composer(id);
  }

  @Get('works/:id')
  work(@Param('id') id: string) {
    return this.classical.work(id);
  }
}
