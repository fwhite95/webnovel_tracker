import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_state.dart';

/// Drives the home list: subscribes to the repository stream, and applies
/// sort / tag-filter changes. Depends only on [EntryRepository].
class EntryListBloc extends Bloc<EntryListEvent, EntryListState> {
  EntryListBloc(this._repository) : super(const EntryListState.loading()) {
    on<EntryListStarted>(_onStarted);
    on<EntryListSortChanged>(_onSortChanged);
    on<EntryListTagFilterChanged>(_onTagFilterChanged);
    on<EntryListDataUpdated>(_onDataUpdated);
    on<EntryListEntryOpened>(_onEntryOpened);
    on<EntryListEntryDeleted>(_onEntryDeleted);
    on<EntryListEntryUpsert>(_onEntryUpsert);
  }

  final EntryRepository _repository;

  StreamSubscription<List<Entry>>? _subscription;

  List<Entry> _all = const [];
  EntrySort _sort = EntrySort.lastOpened;
  String? _tagFilter;

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

  Future<void> _onTagFilterChanged(
    EntryListTagFilterChanged event,
    Emitter<EntryListState> emit,
  ) async {
    _tagFilter = event.tag;
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
    final allTags = <String>{for (final e in _all) ...e.tags}.toList()..sort();

    List<Entry> visible = _tagFilter == null
        ? _all
        : _all.where((e) => e.tags.contains(_tagFilter)).toList();

    visible = [...visible]
      ..sort(
        (a, b) => switch (_sort) {
          EntrySort.lastOpened => (b.lastOpened ?? b.dateAdded).compareTo(
            a.lastOpened ?? a.dateAdded,
          ),
          EntrySort.dateAdded => b.dateAdded.compareTo(a.dateAdded),
        },
      );

    return EntryListLoaded(
      entries: visible,
      allTags: allTags,
      sort: _sort,
      tagFilter: _tagFilter,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
