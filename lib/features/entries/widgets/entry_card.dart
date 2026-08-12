import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webnovel_tracker/data/database/app_database.dart';

/// A single entry rendered as a card: title, url, tag chips, date added.
/// Tapping opens the URL in the external browser; trailing icon buttons
/// for edit / delete.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Entry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      shadowColor: colors.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.chapter.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Chapter ${entry.chapter}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (entry.url.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.link, size: 16, color: colors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in entry.tags) _TagChip(label: tag),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Added ${DateFormat.yMMMd().format(entry.dateAdded)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    color: colors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact tag pill; smaller than a Material [Chip].
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.onSecondaryContainer),
      ),
    );
  }
}
