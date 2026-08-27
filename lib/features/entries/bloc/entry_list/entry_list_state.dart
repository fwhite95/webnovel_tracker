import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';

part 'entry_list_state.freezed.dart';

@freezed
sealed class EntryListState with _$EntryListState {
  const factory EntryListState.loading() = EntryListLoading;

  const factory EntryListState.loaded({
    required List<Entry> entries,
    required int totalCount,
    @Default(EntrySort.lastOpened) EntrySort sort,
  }) = EntryListLoaded;

  const factory EntryListState.error(String message) = EntryListError;
}
