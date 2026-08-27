import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/data/entry_repository.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_state.dart';

/// AppBar sort control: a popup menu with a checkmark on the active option.
class EntrySortMenu extends StatelessWidget {
  const EntrySortMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EntryListBloc, EntryListState, EntrySort>(
      selector: (state) =>
          state is EntryListLoaded ? state.sort : EntrySort.lastOpened,
      builder: (context, currentSort) {
        return PopupMenuButton<EntrySort>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          onSelected: (sort) => context.read<EntryListBloc>().add(
            EntryListEvent.sortChanged(sort),
          ),
          itemBuilder: (context) => [
            _item(EntrySort.lastOpened, 'Last opened', currentSort),
            _item(EntrySort.dateAdded, 'Date added', currentSort),
            _item(EntrySort.title, 'Title (A-Z)', currentSort),
          ],
        );
      },
    );
  }

  PopupMenuItem<EntrySort> _item(
    EntrySort value,
    String label,
    EntrySort current,
  ) {
    return PopupMenuItem<EntrySort>(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: value == current ? const Icon(Icons.check, size: 18) : null,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
