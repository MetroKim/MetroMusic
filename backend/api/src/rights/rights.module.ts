import { Module } from '@nestjs/common';
import { RightsDecisionService } from './rights-decision.service';

@Module({
  providers: [RightsDecisionService],
  exports: [RightsDecisionService],
})
export class RightsModule {}
