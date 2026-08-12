import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';

part 'new_entry_state.freezed.dart';

/// Lifecycle of the new-entry form. [editing] covers both the URL-only step
/// and the revealed-fields step (distinguished by [NewEntryState.showDetails]).
/// [duplicateFound] means the save is paused on the user picking between
/// updating the matched entry and adding a second one.
enum NewEntryStatus { editing, fetching, saving, duplicateFound, saved }

@freezed
abstract class NewEntryState with _$NewEntryState {
  const factory NewEntryState({
    @Default(NewEntryStatus.editing) NewEntryStatus status,

    /// Whether the editable title/tags/progress fields are visible.
    @Default(false) bool showDetails,

    /// Message shown under the fields (e.g. after a failed title fetch).
    String? errorMessage,

    /// Stored entry matching what's being saved. Non-null from
    /// [NewEntryStatus.duplicateFound] onwards; the sheet swaps to the merge
    /// view while it is set.
    Entry? duplicate,

    /// The entry that would have been inserted, kept alongside [duplicate] so
    /// either choice can be carried out without the user re-submitting.
    Entry? pending,
  }) = _NewEntryState;
}
