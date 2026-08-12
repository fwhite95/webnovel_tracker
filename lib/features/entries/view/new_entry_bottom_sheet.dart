import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/core/di.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_state.dart';
import 'package:webnovel_tracker/features/entries/widgets/duplicate_entry_form.dart';
import 'package:webnovel_tracker/shared/widgets/entry_text_field.dart';

import 'package:webnovel_tracker/shared/widgets/grab_handle.dart';

/// Bottom sheet for adding an entry. The user enters a URL; the bloc tries to
/// fetch the title and save. If that fails, the editable fields are revealed.
///
/// [initialUrl] pre-fills the URL — that's the share-intent path, where the URL
/// arrives from outside the app and only needs confirming. Both paths are the
/// same form, so they share the busy / error / fetch-fallback handling.
///
/// If the bloc finds an entry for the same novel, the sheet swaps its body for
/// [DuplicateEntryForm] rather than opening a dialog — one route, so there's no
/// second context to manage and dismissing the sheet cancels the whole thing.
class NewEntryBottomSheet extends StatefulWidget {
  const NewEntryBottomSheet({super.key, this.initialUrl});

  /// URL to start with, or null to start empty and focus the field.
  final String? initialUrl;

  /// Presents the sheet with its own [NewEntryBloc]. The bloc is a factory
  /// registration, so every presentation starts from a clean state.
  static Future<void> show(BuildContext context, {String? initialUrl}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => getIt<NewEntryBloc>(),
        child: NewEntryBottomSheet(initialUrl: initialUrl),
      ),
    );
  }

  @override
  State<NewEntryBottomSheet> createState() => _NewEntryBottomSheetState();
}

class _NewEntryBottomSheetState extends State<NewEntryBottomSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _chapterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) =>
      raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  void _submit() {
    context.read<NewEntryBloc>().add(
      NewEntryEvent.submitted(
        url: _urlController.text,
        title: _titleController.text,
        chapter: _chapterController.text,
        tags: _parseTags(_tagsController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 2 / 3;

    return BlocConsumer<NewEntryBloc, NewEntryState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == NewEntryStatus.saved) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final busy =
            state.status == NewEntryStatus.fetching ||
            state.status == NewEntryStatus.saving;

        return Padding(
          // Lift the sheet above the keyboard.
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: GrabHandle()),
                  const SizedBox(height: 16),
                  if (state.duplicate != null)
                    DuplicateEntryForm(
                      existing: state.duplicate!,
                      pending: state.pending!,
                      busy: busy,
                      onResolved:
                          ({required updateExisting, required chapter}) =>
                              context.read<NewEntryBloc>().add(
                                NewEntryEvent.duplicateResolved(
                                  updateExisting: updateExisting,
                                  chapter: chapter,
                                ),
                              ),
                    )
                  else
                    ..._entryFields(context, state, busy: busy),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The normal add form: URL, plus the details once they're revealed.
  List<Widget> _entryFields(
    BuildContext context,
    NewEntryState state, {
    required bool busy,
  }) {
    final theme = Theme.of(context);
    final fromShare = widget.initialUrl != null;

    return [
      Text(
        fromShare ? 'Save shared link' : 'New entry',
        style: theme.textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      EntryTextField(
        controller: _urlController,
        label: 'URL',
        hint: 'https://...',
        prefixIcon: Icons.link,
        keyboardType: TextInputType.url,
        textInputAction: state.showDetails
            ? TextInputAction.next
            : TextInputAction.done,
        // A shared URL is already filled in — don't raise the
        // keyboard just to confirm it.
        autofocus: !fromShare,
        enabled: !busy,
        onSubmitted: (_) {
          if (!busy && !state.showDetails) _submit();
        },
      ),
      if (state.showDetails) ...[
        const SizedBox(height: 12),
        EntryTextField(
          controller: _titleController,
          label: 'Title',
          enabled: !busy,
        ),
        const SizedBox(height: 12),
        EntryTextField(
          controller: _chapterController,
          label: 'Chapter',
          hint: 'e.g. 48',
          enabled: !busy,
        ),
        const SizedBox(height: 12),
        EntryTextField(
          controller: _tagsController,
          label: 'Tags',
          hint: 'comma, separated',
          enabled: !busy,
        ),
      ],
      if (state.errorMessage != null) ...[
        const SizedBox(height: 12),
        Text(
          state.errorMessage!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ],
      const SizedBox(height: 20),
      Row(
        children: [
          if (!state.showDetails)
            TextButton(
              onPressed: busy
                  ? null
                  : () => context.read<NewEntryBloc>().add(
                      const NewEntryEvent.detailsRequested(),
                    ),
              child: const Text('Add details manually'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(state.showDetails ? 'Save' : 'Add'),
          ),
        ],
      ),
    ];
  }
}
