import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// Shared form for creating a new entry and editing an existing one.
///
/// Fields: url, title (with a "fetch from page" action via TitleFetcher),
/// tags, progress note. Save -> EntryRepository.upsert (via a bloc/cubit).
class AddEditScreen extends StatefulWidget {
  const AddEditScreen({super.key, this.existing});

  /// The entry being edited, or null when adding a new one.
  final Entry? existing;

  bool get isEditing => existing != null;

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: Form with url/title/tags/progress fields + save action.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit entry' : 'Add entry'),
      ),
      body: const Center(child: Text('Add / edit form')),
    );
  }
}
