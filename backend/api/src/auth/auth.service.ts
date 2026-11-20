import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { randomBytes, randomUUID } from 'crypto';
import { PrismaService } from '../prisma.service';

export interface AuthResult {
  accessToken: string;
  refreshToken: string;
  user: { id: string; email: string; displayName: string | null };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  private refreshExpiry(): Date {
    return new Date(Date.now() + 30 * 24 * 3600 * 1000);
  }

  private async issueTokens(
    user: { id: string; email: string; displayName: string | null },
    refreshOverride?: string,
  ): Promise<AuthResult> {
    const accessToken = await this.jwt.signAsync(
      { sub: user.id, email: user.email },
      { expiresIn: '15m' },
    );
    const refreshToken = refreshOverride ?? randomBytes(32).toString('hex');
    if (!refreshOverride) {
      await this.prisma.refreshToken.create({
        data: {
          token: refreshToken,
          familyId: randomUUID(),
          userId: user.id,
          expiresAt: this.refreshExpiry(),
        },
      });
    }
    return {
      accessToken,
      refreshToken,
      user: { id: user.id, email: user.email, displayName: user.displayName },
    };
  }

  async register(
    email: string,
    password: string,
    displayName?: string,
  ): Promise<AuthResult> {
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new ConflictException('EMAIL_TAKEN');

    const passwordHash = await argon2.hash(password, {
      type: argon2.argon2id,
    });
    const user = await this.prisma.user.create({
      data: { email, passwordHash, displayName: displayName ?? null },
    });
    return this.issueTokens(user);
  }

  async login(email: string, password: string): Promise<AuthResult> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('INVALID_CREDENTIALS');

    const valid = await argon2
      .verify(user.passwordHash, password)
      .catch(() => false);
    if (!valid) throw new UnauthorizedException('INVALID_CREDENTIALS');
    return this.issueTokens(user);
  }

  async refresh(refreshToken: string): Promise<AuthResult> {
    const token = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!token || token.revokedAt !== null || token.expiresAt < new Date()) {
      if (token) {
        await this.prisma.refreshToken.updateMany({
          where: { familyId: token.familyId, revokedAt: null },
          data: { revokedAt: new Date() },
        });
      }
      throw new UnauthorizedException('REFRESH_REUSED_OR_INVALID');
    }

    const rotated = randomBytes(32).toString('hex');
    await this.prisma.refreshToken.update({
      where: { token: refreshToken },
      data: { token: rotated, expiresAt: this.refreshExpiry() },
    });

    return this.issueTokens(token.user, rotated);
  }

  async logout(refreshToken: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { token: refreshToken },
      data: { revokedAt: new Date() },
    });
  }

  async profile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('USER_NOT_FOUND');
    return user;
  }

  async listSessions(userId: string) {
    return this.prisma.refreshToken.findMany({
      where: { userId, revokedAt: null },
      select: { id: true, createdAt: true, expiresAt: true },
    });
  }

  async revokeSession(userId: string, tokenId: string): Promise<void> {
    const result = await this.prisma.refreshToken.updateMany({
      where: { id: tokenId, userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (result.count === 0) throw new NotFoundException('SESSION_NOT_FOUND');
  }
}
