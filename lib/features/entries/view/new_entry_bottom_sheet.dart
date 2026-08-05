import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_event.dart';
import 'package:webnovel_tracker/features/entries/bloc/new_entry/new_entry_state.dart';
import 'package:webnovel_tracker/shared/widgets/entry_text_field.dart';

/// Bottom sheet for adding an entry. The user enters a URL; the bloc tries to
/// fetch the title and save. If that fails, the editable fields are revealed.
///
/// Expects a [NewEntryBloc] provided above it (see [HomeScreen]).
class NewEntryBottomSheet extends StatefulWidget {
  const NewEntryBottomSheet({super.key});

  @override
  State<NewEntryBottomSheet> createState() => _NewEntryBottomSheetState();
}

class _NewEntryBottomSheetState extends State<NewEntryBottomSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _progressController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) =>
      raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  void _submit() {
    context.read<NewEntryBloc>().add(
      NewEntryEvent.submitted(
        url: _urlController.text,
        title: _titleController.text,
        tags: _parseTags(_tagsController.text),
        progressNote: _progressController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  const Center(child: _GrabHandle()),
                  const SizedBox(height: 16),
                  Text('New entry', style: theme.textTheme.titleLarge),
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
                    autofocus: true,
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
                      controller: _tagsController,
                      label: 'Tags',
                      hint: 'comma, separated',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    EntryTextField(
                      controller: _progressController,
                      label: 'Progress note',
                      hint: 'e.g. ch. 47',
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(state.showDetails ? 'Save' : 'Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The little drag indicator at the top of the sheet.
class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
