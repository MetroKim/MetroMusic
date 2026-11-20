import 'package:drift/drift.dart';

import 'breezze_database.dart';

/// Drains the sync outbox against the backend once the user is signed
/// in. Replays ops in order; the drain deletes each op only after the
/// backend accepted it.
class SyncOutboxDao {
  final BreezzeDatabase _db;
  SyncOutboxDao(this._db);

  Future<List<SyncOutboxData>> pending() {
    return (_db.select(_db.syncOutbox)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Removes a single op after the backend accepted it.
  Future<void> remove(int id) async {
    await (_db.delete(_db.syncOutbox)..where((t) => t.id.equals(id))).go();
  }

  /// Removes a single op WITHOUT backend confirmation — for ops the
  /// backend cannot ever accept (e.g. unknown op type).
  Future<void> discard(int id) => remove(id);

  Future<void> clear() async {
    await _db.delete(_db.syncOutbox).go();
  }
}
