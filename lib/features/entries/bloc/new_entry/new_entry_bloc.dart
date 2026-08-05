import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_state.dart';
import 'package:webnovel_tracker/services/title_fetcher.dart';

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
      final fetched = await _titleFetcher.fetchTitle(url);
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
      await _save(url: url, title: fetched, emit: emit);
      return;
    }

    // Details step: save exactly what the user entered (title falls back to
    // the URL so the card always has something to show).
    final title = event.title.trim().isEmpty ? url : event.title.trim();
    await _save(
      url: url,
      title: title,
      tags: event.tags,
      progressNote: event.progressNote.trim(),
      emit: emit,
    );
  }

  Future<void> _save({
    required String url,
    required String title,
    List<String> tags = const [],
    String progressNote = '',
    required Emitter<NewEntryState> emit,
  }) async {
    emit(state.copyWith(status: NewEntryStatus.saving, errorMessage: null));
    final entry = Entry(
      id: _uuid.v4(),
      url: url,
      title: title,
      tags: tags,
      progressNote: progressNote,
      dateAdded: DateTime.now(),
    );
    await _repository.upsert(entry);
    emit(state.copyWith(status: NewEntryStatus.saved));
  }
}
