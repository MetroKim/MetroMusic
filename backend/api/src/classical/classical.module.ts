import { Module } from '@nestjs/common';
import { ClassicalController } from './classical.controller';
import { ClassicalService } from './classical.service';

@Module({
  controllers: [ClassicalController],
  providers: [ClassicalService],
  exports: [ClassicalService],
})
export class ClassicalModule {}
