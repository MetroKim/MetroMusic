import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';

/**
 * Server-side RBAC gate (Plan §17.2, §23): authorization is decided by
 * persisted UserRole rows, never by client claims. Runs after
 * JwtAuthGuard, which populates request.user.
 */
@Injectable()
export class AdminRoleGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId: string | undefined = request.user?.id;
    if (!userId) throw new ForbiddenException('AUTH_REQUIRED');

    const role = await this.prisma.userRole.findFirst({
      where: { userId, role: 'admin' },
    });
    if (!role) throw new ForbiddenException('INSUFFICIENT_ROLE');
    return true;
  }
}
