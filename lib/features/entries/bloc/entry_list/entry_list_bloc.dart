import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_state.dart';

/// Drives the home list: subscribes to the repository stream, and applies
/// sort / search changes. Depends only on [EntryRepository].
class EntryListBloc extends Bloc<EntryListEvent, EntryListState> {
  EntryListBloc(this._repository) : super(const EntryListState.loading()) {
    on<EntryListStarted>(_onStarted);
    on<EntryListSortChanged>(_onSortChanged);
    on<EntryListSearchQueryChanged>(_onSearchQueryChanged);
    on<EntryListDataUpdated>(_onDataUpdated);
    on<EntryListEntryOpened>(_onEntryOpened);
    on<EntryListEntryDeleted>(_onEntryDeleted);
    on<EntryListEntryUpsert>(_onEntryUpsert);
  }

  final EntryRepository _repository;

  StreamSubscription<List<Entry>>? _subscription;

  List<Entry> _all = const [];
  EntrySort _sort = EntrySort.lastOpened;
  String _searchQuery = '';

  Future<void> _onStarted(
    EntryListStarted event,
    Emitter<EntryListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _repository.watchEntries().listen(
      (entries) => add(EntryListEvent.dataUpdated(entries)),
    );
  }

  Future<void> _onSortChanged(
    EntryListSortChanged event,
    Emitter<EntryListState> emit,
  ) async {
    _sort = event.sort;
    emit(_buildLoaded());
  }

  Future<void> _onSearchQueryChanged(
    EntryListSearchQueryChanged event,
    Emitter<EntryListState> emit,
  ) async {
    _searchQuery = event.query;
    emit(_buildLoaded());
  }

  Future<void> _onDataUpdated(
    EntryListDataUpdated event,
    Emitter<EntryListState> emit,
  ) async {
    _all = event.entries;
    emit(_buildLoaded());
  }

  Future<void> _onEntryOpened(
    EntryListEntryOpened event,
    Emitter<EntryListState> emit,
  ) async {
    // Just records the open; launching the URL is the view's job (url_launcher).
    // The list refreshes on its own via the repository stream.
    await _repository.markOpened(event.id);
  }

  Future<void> _onEntryUpsert(
    EntryListEntryUpsert event,
    Emitter<EntryListState> emit,
  ) async {
    await _repository.upsert(event.entry);
    emit(_buildLoaded());
  }

  Future<void> _onEntryDeleted(
    EntryListEntryDeleted event,
    Emitter<EntryListState> emit,
  ) async {
    await _repository.delete(event.id);
  }

  EntryListLoaded _buildLoaded() {
    Iterable<Entry> visible = _all;

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = visible.where(
        (e) =>
            e.title.toLowerCase().contains(query) ||
            e.tags.any((t) => t.toLowerCase().contains(query)),
      );
    }

    final sorted = visible.toList()
      ..sort(
        (a, b) => switch (_sort) {
          EntrySort.lastOpened => (b.lastOpened ?? b.dateAdded).compareTo(
            a.lastOpened ?? a.dateAdded,
          ),
          EntrySort.dateAdded => b.dateAdded.compareTo(a.dateAdded),
          EntrySort.title => a.title.toLowerCase().compareTo(
            b.title.toLowerCase(),
          ),
        },
      );

    return EntryListLoaded(
      entries: sorted,
      totalCount: _all.length,
      sort: _sort,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
