import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsIn, IsUUID } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminRoleGuard } from '../auth/admin-role.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AdminService } from './admin.service';

export class RoleDto {
  @IsUUID()
  userId!: string;

  @IsIn(['admin', 'moderator', 'user'])
  role!: string;
}

// Admin RBAC (Plan §17.2): every /admin/* route requires a valid JWT
// AND a persisted 'admin' UserRole row. Non-admins get 403.
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminRoleGuard)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('dashboard')
  dashboard() {
    return this.admin.dashboard();
  }

  @Get('roles')
  listRoles(@Query('userId') userId: string) {
    return this.admin.listRoles(userId);
  }

  @Post('roles')
  grantRole(@CurrentUser() actor: string, @Body() dto: RoleDto) {
    return this.admin.createUserRole(dto.userId, dto.role, actor);
  }

  @Delete('roles')
  revokeRole(@Body() dto: RoleDto) {
    return this.admin.revokeUserRole(dto.userId, dto.role);
  }

  @Get('takedowns')
  takedowns() {
    return this.admin.listTakedowns();
  }

  @Post('takedowns/:id/resolve')
  resolve(@Param('id', ParseUUIDPipe) id: string) {
    return this.admin.resolveTakedown(id);
  }
}
