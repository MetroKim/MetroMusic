import 'package:drift/drift.dart';

import 'breezze_database.dart';

/// External-ID → catalog-ID mapping DAO. Cached locally so the drain
/// resolves a track once, then reuses the mapping forever.
class CatalogIdMapDao {
  final BreezzeDatabase _db;
  CatalogIdMapDao(this._db);

  Future<String?> lookup(String externalId) async {
    final row = await (_db.select(_db.catalogIdMap)
          ..where((t) => t.externalId.equals(externalId)))
        .getSingleOrNull();
    return row?.catalogId;
  }

  Future<void> save(String externalId, String catalogId) {
    return (_db.into(_db.catalogIdMap)).insertOnConflictUpdate(
      CatalogIdMapCompanion.insert(
        externalId: externalId,
        catalogId: catalogId,
      ),
    );
  }
}
