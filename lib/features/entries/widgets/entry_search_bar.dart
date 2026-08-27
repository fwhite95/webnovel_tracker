import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/shared/widgets/entry_text_field.dart';

/// Search field for the home list; filters by title or tag.
///
/// Owns its own [TextEditingController] so its state (and cursor position)
/// survives rebuilds triggered by [EntryListBloc] state changes.
class EntrySearchBar extends StatefulWidget {
  const EntrySearchBar({super.key});

  @override
  State<EntrySearchBar> createState() => _EntrySearchBarState();
}

class _EntrySearchBarState extends State<EntrySearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntryTextField(
      controller: _controller,
      label: 'Search',
      hint: 'Title or tag',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: (value) => context.read<EntryListBloc>().add(
        EntryListEvent.searchQueryChanged(value),
      ),
    );
  }
}
