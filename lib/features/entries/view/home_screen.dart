import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_state.dart';
import 'package:webnovel_tracker/features/entries/view/new_entry_bottom_sheet.dart';
import 'package:webnovel_tracker/features/entries/widgets/entry_card.dart';

/// Home screen: the list of tracked entries.
///
/// Reads [EntryListState] via [BlocBuilder]; sort/filter dispatch events to
/// [EntryListBloc]. FAB -> [NewEntryBottomSheet]; overflow -> export / import.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Novel Tracker')),
      body: BlocBuilder<EntryListBloc, EntryListState>(
        builder: (context, state) {
          return switch (state) {
            EntryListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            EntryListLoaded() => ListView.separated(
              itemCount: state.entries.length,
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                return EntryCard(
                  entry: entry,
                  // TODO: onTap -> open URL via url_launcher + mark opened,
                  // onEdit -> the entry form sheet.
                  onDelete: () => context.read<EntryListBloc>().add(
                    EntryListEvent.entryDeleted(entry.id),
                  ),
                );
              },
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
