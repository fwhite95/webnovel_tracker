import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_state.dart';
import 'package:webnovel_tracker/services/title_fetcher.dart';
import 'package:webnovel_tracker/shared/utils/entry_utils.dart';

/// Backs the "new entry" bottom sheet. Given a URL it tries to fetch the page
/// title and save straight away; if that fails it asks the view to reveal the
/// editable fields. Saves go through [EntryRepository] — the home list refreshes
/// on its own via the repository stream, so this bloc stays decoupled from
/// [EntryListBloc].
class NewEntryBloc extends Bloc<NewEntryEvent, NewEntryState> {
  NewEntryBloc(this._repository, this._titleFetcher)
    : super(const NewEntryState()) {
    on<NewEntryDetailsRequested>(_onDetailsRequested);
    on<NewEntrySubmitted>(_onSubmitted);
    on<NewEntryDuplicateResolved>(_onDuplicateResolved);
  }

  final EntryRepository _repository;
  final TitleFetcher _titleFetcher;
  final _uuid = const Uuid();

  void _onDetailsRequested(
    NewEntryDetailsRequested event,
    Emitter<NewEntryState> emit,
  ) {
    emit(state.copyWith(showDetails: true, errorMessage: null));
  }

  Future<void> _onSubmitted(
    NewEntrySubmitted event,
    Emitter<NewEntryState> emit,
  ) async {
    final url = event.url.trim();
    if (url.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter a URL.'));
      return;
    }

    // URL-only step: try to fetch the title before falling back to the form.
    if (!state.showDetails) {
      emit(state.copyWith(status: NewEntryStatus.fetching, errorMessage: null));
      final fetched = await _titleFetcher.fetch(url);
      if (fetched == null) {
        emit(
          state.copyWith(
            status: NewEntryStatus.editing,
            showDetails: true,
            errorMessage:
                "Couldn't fetch the title — please fill in the details.",
          ),
        );
        return;
      }
      await _save(
        url: url,
        title: fetched.title,
        chapter: fetched.chapter,
        emit: emit,
      );
      return;
    }

    // Details step: save what the user entered, but still split the title —
    // typing "Chapter 12 - X" into it should fill the chapter column, not bake
    // the number into the series name.
    //
    // An empty title falls back to the URL so the card has something to show,
    // and that fallback must skip the splitter: stripping a "chapter-48" slug
    // out of a URL would leave a mangled link as the title.
    final typed = event.title.trim();
    final explicit = event.chapter.trim();
    final parts = typed.isEmpty
        ? (title: url, chapter: chapterInUrl(url))
        : splitTitle(typed);

    await _save(
      url: url,
      title: parts.title,
      chapter: explicit.isEmpty ? parts.chapter : explicit,
      tags: event.tags,
      emit: emit,
    );
  }

  Future<void> _save({
    required String url,
    required String title,
    String chapter = '',
    List<String> tags = const [],
    required Emitter<NewEntryState> emit,
  }) async {
    emit(state.copyWith(status: NewEntryStatus.saving, errorMessage: null));
    final entry = Entry(
      id: _uuid.v4(),
      url: url,
      title: title,
      chapter: chapter,
      tags: tags,
      dateAdded: DateTime.now(),
    );
    // Adding a chapter of something already tracked is the common case, so
    // hand the choice back to the sheet instead of quietly inserting a second
    // row for the same novel.
    final duplicate = await _findDuplicate(entry);
    if (duplicate != null) {
      emit(
        state.copyWith(
          status: NewEntryStatus.duplicateFound,
          duplicate: duplicate,
          pending: entry,
        ),
      );
      return;
    }

    await _repository.upsert(entry);
    emit(state.copyWith(status: NewEntryStatus.saved));
  }

  Future<void> _onDuplicateResolved(
    NewEntryDuplicateResolved event,
    Emitter<NewEntryState> emit,
  ) async {
    final existing = state.duplicate;
    final pending = state.pending;
    if (existing == null || pending == null) return;

    emit(state.copyWith(status: NewEntryStatus.saving, errorMessage: null));
    // Updating moves the stored URL on to the chapter just submitted, so
    // opening the card resumes from it. The title is left alone — a
    // hand-edited one shouldn't be clobbered by a fetched variant.
    await _repository.upsert(
      event.updateExisting
          ? existing.copyWith(
              url: pending.url,
              chapter: event.chapter.trim(),
              lastOpened: Value(DateTime.now()),
            )
          : pending.copyWith(chapter: event.chapter.trim()),
    );
    emit(state.copyWith(status: NewEntryStatus.saved));
  }

  /// The first stored entry for the same site and series as [candidate], or
  /// null if there isn't one. Now that the chapter lives in its own column
  /// this is just a field comparison; see [titleKey] for the normalisation.
  Future<Entry?> _findDuplicate(Entry candidate) async {
    final host = hostOf(candidate.url);
    if (host == null) return null;
    final key = titleKey(candidate.title);

    for (final entry in await _repository.all()) {
      if (hostOf(entry.url) == host && titleKey(entry.title) == key) {
        return entry;
      }
    }
    return null;
  }
}
