import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsIn, IsUUID } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AdminService } from './admin.service';

export class RoleDto {
  @IsUUID()
  userId!: string;

  @IsIn(['admin', 'moderator', 'user'])
  role!: string;
}

// NOTE: full admin RBAC (admin-only guard) lands with the AdminRole
// model; today these endpoints are authenticated but not yet
// role-gated. Track in the gap register.
@Controller('admin')
@UseGuards(JwtAuthGuard)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('dashboard')
  dashboard() {
    return this.admin.dashboard();
  }

  @Get('takedowns')
  takedowns() {
    return this.admin.listTakedowns();
  }

  @Post('takedowns/:id/resolve')
  resolve(@Param('id') id: string) {
    return this.admin.resolveTakedown(id);
  }

  @Post('roles')
  grantRole(@CurrentUser() actor: string, @Body() dto: RoleDto) {
    return this.admin.createUserRole(dto.userId, dto.role);
  }
}
