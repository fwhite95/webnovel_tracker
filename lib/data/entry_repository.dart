import 'package:drift/drift.dart' show Value;
import 'package:webnovel_tracker/data/database/app_database.dart';

/// How to order the entry list.
enum EntrySort { lastOpened, dateAdded }

/// Domain-facing wrapper over [AppDatabase]. Blocs depend on this, not on
/// Drift directly, so the persistence layer can change without touching them.
///
/// The generated Drift [Entry] class is used as the entity across layers.
/// Sorting / tag-filtering lives in the bloc, so the reads here are thin.
class EntryRepository {
  EntryRepository(this._db);

  final AppDatabase _db;

  /// Unfiltered, unsorted reactive stream of all entries. The bloc shapes it.
  Stream<List<Entry>> watchEntries() => _db.watchAllEntries();

  Future<Entry?> byId(String id) => _db.getEntry(id);

  /// Inserts or updates an entry.
  Future<void> upsert(Entry entry) => _db.upsertEntry(entry.toCompanion(true));

  Future<void> delete(String id) => _db.deleteEntry(id);

  /// Records that [id] was just opened. No-op if the entry is gone.
  Future<void> markOpened(String id) async {
    final entry = await _db.getEntry(id);
    if (entry == null) return;
    await _db.upsertEntry(
      entry.copyWith(lastOpened: Value(DateTime.now())).toCompanion(true),
    );
  }

  // --- Backup helpers (used by BackupService) -------------------------------

  Future<List<Entry>> allForExport() => _db.getAllEntries();

  /// Replaces the entire store with [items].
  Future<void> replaceAll(List<Entry> items) async {
    await _db.clearAll();
    for (final entry in items) {
      await _db.upsertEntry(entry.toCompanion(true));
    }
  }

  /// Adds [items], overwriting any with a matching id.
  Future<void> mergeAll(List<Entry> items) async {
    for (final entry in items) {
      await _db.upsertEntry(entry.toCompanion(true));
    }
  }
}
