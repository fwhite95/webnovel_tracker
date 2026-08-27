import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';

part 'entry_list_event.freezed.dart';

@freezed
sealed class EntryListEvent with _$EntryListEvent {
  /// Start listening to the repository stream.
  const factory EntryListEvent.started() = EntryListStarted;

  const factory EntryListEvent.sortChanged(EntrySort sort) =
      EntryListSortChanged;

  const factory EntryListEvent.searchQueryChanged(String query) =
      EntryListSearchQueryChanged;

  /// Internal: new data arrived from the repository stream.
  const factory EntryListEvent.dataUpdated(List<Entry> entries) =
      EntryListDataUpdated;

  const factory EntryListEvent.upsertEntry(Entry entry) = EntryListEntryUpsert;

  const factory EntryListEvent.entryOpened(String id) = EntryListEntryOpened;

  const factory EntryListEvent.entryDeleted(String id) = EntryListEntryDeleted;
}
