import 'package:drift/drift.dart' hide Count;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'breezze_database.dart';
import 'catalog_id_map_dao.dart';
import 'favorites_dao.dart';
import 'recently_played_dao.dart';
import 'sync_outbox_dao.dart';

/// One database instance for the whole app; DAOs hang off it.
final breezzeDatabaseProvider = Provider<BreezzeDatabase>(
  (ref) => BreezzeDatabase.open(),
  // DB lives for the app's lifetime; no dispose needed.
);

final favoritesDaoProvider = Provider<FavoritesDao>(
  (ref) => FavoritesDao(ref.watch(breezzeDatabaseProvider)),
);

final recentlyPlayedDaoProvider = Provider<RecentlyPlayedDao>(
  (ref) => RecentlyPlayedDao(ref.watch(breezzeDatabaseProvider)),
);

final syncOutboxDaoProvider = Provider<SyncOutboxDao>(
  (ref) => SyncOutboxDao(ref.watch(breezzeDatabaseProvider)),
);

final catalogIdMapDaoProvider = Provider<CatalogIdMapDao>(
  (ref) => CatalogIdMapDao(ref.watch(breezzeDatabaseProvider)),
);
