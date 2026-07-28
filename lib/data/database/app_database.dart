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
  TextColumn get title => text()();

  /// Tags / collection labels, JSON-encoded via [TagListConverter].
  TextColumn get tags =>
      text().map(const TagListConverter()).withDefault(const Constant('[]'))();

  /// Free-text progress note, e.g. "ch. 47".
  TextColumn get progressNote => text().withDefault(const Constant(''))();

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
  int get schemaVersion => 1;

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
