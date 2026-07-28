import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/entry_repository.dart';

part 'entry_list_state.freezed.dart';

@freezed
sealed class EntryListState with _$EntryListState {
  const factory EntryListState.loading() = EntryListLoading;

  const factory EntryListState.loaded({
    required List<Entry> entries,
    required List<String> allTags,
    @Default(EntrySort.lastOpened) EntrySort sort,
    String? tagFilter,
  }) = EntryListLoaded;

  const factory EntryListState.error(String message) = EntryListError;
}
