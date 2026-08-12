import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Stores a `List<String>` of tags as a JSON string in a single text column.
class TagListConverter extends TypeConverter<List<String>, String> {
  const TagListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb) as List;
    return decoded.map((e) => e.toString()).toList();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// A single tracked web novel. Drift generates the immutable `Entry` data
/// class and `EntriesCompanion` (used for inserts/updates) from this table.
class Entries extends Table {
  /// UUID string, also the primary key.
  TextColumn get id => text()();

  TextColumn get url => text()();

  /// The series on its own, with any chapter marker split off into [chapter].
  TextColumn get title => text()();

  /// Reading position, e.g. "48" or "12.5". Empty when unknown — chapter
  /// markers don't appear on every page title, and manual entries may skip it.
  TextColumn get chapter => text().withDefault(const Constant(''))();

  /// Tags / collection labels, JSON-encoded via [TagListConverter].
  TextColumn get tags =>
      text().map(const TagListConverter()).withDefault(const Constant('[]'))();

  DateTimeColumn get dateAdded => dateTime()();

  /// Null until opened at least once.
  DateTimeColumn get lastOpened => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 swapped the free-text progressNote for a dedicated chapter column.
      // Everything stored under v1 was test data, so recreate the table rather
      // than carry it across.
      await m.drop(entries);
      await m.createAll();
    },
  );

  static QueryExecutor _open() => driftDatabase(name: 'webnovel_tracker');

  // --- Queries (stubs) ------------------------------------------------------

  /// Reactive stream of all entries; the UI listens to this.
  Stream<List<Entry>> watchAllEntries() => select(entries).watch();

  Future<List<Entry>> getAllEntries() => select(entries).get();

  Future<Entry?> getEntry(String id) {
    final entry = (select(
      entries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return entry;
  }

  /// Inserts or replaces an entry.
  Future<void> upsertEntry(EntriesCompanion entry) =>
      into(entries).insertOnConflictUpdate(entry);

  Future<void> deleteEntry(String id) =>
      (delete(entries)..where((t) => t.id.equals(id))).go();

  /// Removes every row (used by a "replace" import).
  Future<void> clearAll() => delete(entries).go();
}
