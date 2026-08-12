import 'package:flutter/material.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';
import 'package:webnovel_tracker/shared/widgets/entry_text_field.dart';

/// Reports the user's choice: merge into the existing entry, or add the new
/// one as its own row anyway. [chapter] is whatever the field ended on, and is
/// written either way.
typedef DuplicateResolution =
    void Function({required bool updateExisting, required String chapter});

/// Shown in place of the add form when a submission matches an entry that is
/// already tracked, so the user can move that entry's progress on instead of
/// ending up with two rows for the same novel.
///
/// Owns its chapter controller: the value starts from the incoming chapter
/// rather than from the add form, and nothing outside needs to read it before
/// [onResolved] fires.
class DuplicateEntryForm extends StatefulWidget {
  const DuplicateEntryForm({
    super.key,
    required this.existing,
    required this.pending,
    required this.busy,
    required this.onResolved,
  });

  /// The entry already in the database.
  final Entry existing;

  /// The entry that would have been inserted, held back pending this choice.
  final Entry pending;

  /// Whether a save is in flight — disables both actions.
  final bool busy;

  final DuplicateResolution onResolved;

  @override
  State<DuplicateEntryForm> createState() => _DuplicateEntryFormState();
}

class _DuplicateEntryFormState extends State<DuplicateEntryForm> {
  // The submission's chapter, falling back to what the entry already says so
  // confirming without editing can never blank it. The bloc has already split
  // the chapter out by this point, so there's nothing to parse here.
  late final _chapterController = TextEditingController(
    text: widget.pending.chapter.isEmpty
        ? widget.existing.chapter
        : widget.pending.chapter,
  );

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  void _resolve({required bool updateExisting}) {
    if (widget.busy) return;
    widget.onResolved(
      updateExisting: updateExisting,
      chapter: _chapterController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Already tracking this', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          existing.title,
          style: theme.textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          existing.chapter.isEmpty
              ? 'No chapter recorded yet.'
              : 'Currently on chapter ${existing.chapter}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        EntryTextField(
          controller: _chapterController,
          label: 'Chapter',
          hint: 'e.g. 48',
          enabled: !widget.busy,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resolve(updateExisting: true),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            TextButton(
              onPressed: widget.busy
                  ? null
                  : () => _resolve(updateExisting: false),
              child: const Text('Add as new'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: widget.busy
                  ? null
                  : () => _resolve(updateExisting: true),
              child: widget.busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ],
    );
  }
}
