import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_entry_event.freezed.dart';

@freezed
sealed class NewEntryEvent with _$NewEntryEvent {
  /// Reveal the editable title/chapter/tags fields without fetching.
  const factory NewEntryEvent.detailsRequested() = NewEntryDetailsRequested;

  /// Primary action. With only a URL entered, the bloc tries to fetch the
  /// page title and save; if the fetch fails it reveals the fields. Once the
  /// fields are showing, it saves the provided values as-is — though [title]
  /// is still split, so a chapter typed into it lands in the right column.
  const factory NewEntryEvent.submitted({
    required String url,
    required String title,
    required String chapter,
    required List<String> tags,
  }) = NewEntrySubmitted;

  /// Answers a `duplicateFound` pause. With [updateExisting] the matched entry
  /// absorbs the submission; otherwise the held-back entry is inserted as its
  /// own row. [chapter] is written either way.
  const factory NewEntryEvent.duplicateResolved({
    required bool updateExisting,
    required String chapter,
  }) = NewEntryDuplicateResolved;
}
