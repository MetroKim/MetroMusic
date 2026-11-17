/**
 * Breezze seed (Plan §20 Phase 5-6, MODULES.md gap 5):
 * a small authorized catalog with full rights coverage so the
 * rights matrix, playback resolve, home feed and replay have real
 * data to exercise.
 *
 * Run: npx prisma db seed  (or npx ts-node prisma/seed.ts)
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Idempotent: clear then recreate.
  await prisma.userRole.deleteMany();
  await prisma.recentlyPlayed.deleteMany();
  await prisma.listeningEvent.deleteMany();
  await prisma.territoryAvailability.deleteMany();
  await prisma.rightsUsagePermission.deleteMany();
  await prisma.contentTakedownCase.deleteMany();
  await prisma.providerAttribution.deleteMany();
  await prisma.track.deleteMany();
  await prisma.album.deleteMany();
  await prisma.artist.deleteMany();

  const artist = await prisma.artist.create({
    data: { name: 'Aurora Waves' },
  });

  const album = await prisma.album.create({
    data: {
      title: 'Northern Lights',
      artistId: artist.id,
      releaseDate: new Date('2026-01-01'),
    },
  });

  const streamable = await prisma.track.create({
    data: {
      title: 'First Light',
      artistId: artist.id,
      albumId: album.id,
      duration: 213,
      explicit: false,
    },
  });

  const previewOnly = await prisma.track.create({
    data: {
      title: 'Glacier',
      artistId: artist.id,
      albumId: album.id,
      duration: 198,
      explicit: false,
    },
  });

  const takedownTrack = await prisma.track.create({
    data: {
      title: 'Old Recording',
      artistId: artist.id,
      albumId: album.id,
      duration: 240,
      explicit: false,
    },
  });

  // Territory: worldwide open for the streamable track.
  for (const territory of ['TZ', 'KE', 'UG', 'RW', 'IN']) {
    await prisma.territoryAvailability.create({
      data: { trackId: streamable.id, territory },
    });
  }
  await prisma.territoryAvailability.create({
    data: { trackId: previewOnly.id, territory: 'TZ' },
  });
  await prisma.territoryAvailability.create({
    data: { trackId: takedownTrack.id, territory: 'TZ' },
  });

  // Rights: full stream for the first track; preview-only for the second.
  await prisma.rightsUsagePermission.create({
    data: { trackId: streamable.id, action: 'stream.full' },
  });
  await prisma.rightsUsagePermission.create({
    data: { trackId: previewOnly.id, action: 'preview' },
  });
  await prisma.rightsUsagePermission.create({
    data: { trackId: takedownTrack.id, action: 'stream.full' },
  });

  await prisma.providerAttribution.create({
    data: {
      trackId: streamable.id,
      text: 'Provided under license by Aurora Waves',
    },
  });

  // An active takedown case on the third track.
  await prisma.contentTakedownCase.create({
    data: { trackId: takedownTrack.id, status: 'active' },
  });

  console.log('Seed complete: 1 artist, 1 album, 3 tracks (streamable / preview-only / takedown)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
