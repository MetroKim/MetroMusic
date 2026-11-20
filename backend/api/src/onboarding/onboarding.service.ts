import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class OnboardingService {
  constructor(private readonly prisma: PrismaService) {}

  async savePreferences(
    userId: string,
    dto: {
      country?: string;
      language?: string;
      genres?: string[];
      favoriteArtists?: string[];
    },
  ) {
    return this.prisma.userPreference.upsert({
      where: { userId },
      create: {
        userId,
        country: dto.country,
        language: dto.language,
        genres: dto.genres ?? [],
        favoriteArtists: dto.favoriteArtists ?? [],
      },
      update: {
        country: dto.country,
        language: dto.language,
        genres: dto.genres ?? [],
        favoriteArtists: dto.favoriteArtists ?? [],
      },
    });
  }

  async getPreferences(userId: string) {
    const preferences = await this.prisma.userPreference.findUnique({
      where: { userId },
    });
    // No saved preferences = first-time user. 404 is the explicit
    // signal the app's auth gate uses to decide whether to show
    // onboarding — a 200-null would be ambiguous.
    if (!preferences) throw new NotFoundException('PREFERENCES_NOT_FOUND');
    return preferences;
  }
}
