import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_state.dart';
import 'package:webnovel_tracker/features/entries/view/new_entry_bottom_sheet.dart';
import 'package:webnovel_tracker/features/entries/widgets/entry_card.dart';
import 'package:webnovel_tracker/features/entries/widgets/entry_search_bar.dart';
import 'package:webnovel_tracker/features/entries/widgets/entry_sort_menu.dart';

/// Home screen: the list of tracked entries.
///
/// Reads [EntryListState] via [BlocBuilder]. [EntrySearchBar] dispatches
/// search events (it matches title or tag, so it covers tag filtering too);
/// [EntrySortMenu] in the AppBar dispatches sort changes. FAB ->
/// [NewEntryBottomSheet].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Novel Tracker'),
        actions: const [EntrySortMenu()],
      ),
      body: BlocBuilder<EntryListBloc, EntryListState>(
        builder: (context, state) {
          return switch (state) {
            EntryListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            EntryListLoaded() => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: EntrySearchBar(),
                ),
                Expanded(
                  child: state.entries.isEmpty
                      ? _EmptyState(hasAnyEntries: state.totalCount > 0)
                      : ListView.separated(
                          itemCount: state.entries.length,
                          padding: const EdgeInsets.all(12),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = state.entries[index];
                            return EntryCard(
                              entry: entry,
                              // TODO: onTap -> open URL via url_launcher + mark opened,
                              // onEdit -> the entry form sheet.
                              onDelete: () => context.read<EntryListBloc>()
                                  .add(EntryListEvent.entryDeleted(entry.id)),
                            );
                          },
                        ),
                ),
              ],
            ),
            EntryListError(:final message) => Center(child: Text(message)),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NewEntryBottomSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnyEntries});

  final bool hasAnyEntries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasAnyEntries
              ? 'No entries match your search.'
              : 'No entries yet. Tap + to add your first one.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
