import { AdminRoleGuard } from '../src/auth/admin-role.guard';
import { PrismaService } from '../src/prisma.service';

/**
 * Admin RBAC tests (Plan §17.2):
 * /admin/* access is decided by persisted UserRole rows only.
 */

const prisma = {
  userRole: { findFirst: jest.fn() },
} as unknown as PrismaService;

const guard = new AdminRoleGuard(prisma);

const context = {
  switchToHttp: () => ({ getRequest: () => ({ user: { id: 'u1' } }) }),
} as never;

beforeEach(() => {
  jest.resetAllMocks();
});

describe('AdminRoleGuard', () => {
  it('allows a user with a persisted admin role', async () => {
    (prisma.userRole.findFirst as jest.Mock).mockResolvedValue({
      userId: 'u1',
      role: 'admin',
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(prisma.userRole.findFirst).toHaveBeenCalledWith({
      where: { userId: 'u1', role: 'admin' },
    });
  });

  it('rejects a user without the admin role (403)', async () => {
    (prisma.userRole.findFirst as jest.Mock).mockResolvedValue(null);

    await expect(guard.canActivate(context)).rejects.toThrow(
      'INSUFFICIENT_ROLE',
    );
  });

  it('rejects when no authenticated user is present', async () => {
    const noUserContext = {
      switchToHttp: () => ({ getRequest: () => ({}) }),
    } as never;

    await expect(guard.canActivate(noUserContext)).rejects.toThrow(
      'AUTH_REQUIRED',
    );
    expect(prisma.userRole.findFirst).not.toHaveBeenCalled();
  });
});
