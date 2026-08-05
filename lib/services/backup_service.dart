import 'package:webnovel_tracker/data/entry_repository.dart';

/// How an import reconciles with existing data.
enum ImportMode { merge, replace }

/// JSON export / import for manual backup and device-to-device transfer.
///
/// Export serializes the repository to JSON, writes it to a temp file, and
/// hands it to the OS share sheet. Import lets the user pick a JSON file and
/// repopulates the box (merge or replace).
class BackupService {
  BackupService(this._repository);

  // ignore: unused_field
  final EntryRepository _repository;

  /// Serializes all entries to a JSON string (the export payload).
  String exportToJson() {
    // TODO: build {version, exportedAt, entries: [...]} and jsonEncode it.
    throw UnimplementedError();
  }

  /// Writes the export to a temp file and opens the share sheet.
  Future<void> exportAndShare() {
    // TODO: exportToJson() -> write via path_provider -> share_plus.
    throw UnimplementedError();
  }

  /// Prompts for a JSON file and imports it using [mode].
  Future<void> importFromFile(ImportMode mode) {
    // TODO: file_picker -> read/parse -> repository.mergeAll/replaceAll.
    throw UnimplementedError();
  }
}
