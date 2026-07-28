import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_entry_event.freezed.dart';

@freezed
sealed class NewEntryEvent with _$NewEntryEvent {
  /// Reveal the editable title/tags/progress fields without fetching.
  const factory NewEntryEvent.detailsRequested() = NewEntryDetailsRequested;

  /// Primary action. With only a URL entered, the bloc tries to fetch the
  /// page title and save; if the fetch fails it reveals the fields. Once the
  /// fields are showing, it saves the provided values as-is.
  const factory NewEntryEvent.submitted({
    required String url,
    required String title,
    required List<String> tags,
    required String progressNote,
  }) = NewEntrySubmitted;
}
