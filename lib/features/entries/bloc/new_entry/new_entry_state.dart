import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_entry_state.freezed.dart';

/// Lifecycle of the new-entry form. [editing] covers both the URL-only step
/// and the revealed-fields step (distinguished by [NewEntryState.showDetails]).
enum NewEntryStatus { editing, fetching, saving, saved }

@freezed
abstract class NewEntryState with _$NewEntryState {
  const factory NewEntryState({
    @Default(NewEntryStatus.editing) NewEntryStatus status,

    /// Whether the editable title/tags/progress fields are visible.
    @Default(false) bool showDetails,

    /// Message shown under the fields (e.g. after a failed title fetch).
    String? errorMessage,
  }) = _NewEntryState;
}
