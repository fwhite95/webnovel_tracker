import 'package:flutter/material.dart';

/// Lightweight bottom sheet shown when a URL is shared into the app.
///
/// Pre-filled with the incoming URL; asks for title (auto-fetch via
/// TitleFetcher), tags, and progress before saving via the repository.
class ShareCaptureSheet extends StatefulWidget {
  const ShareCaptureSheet({super.key, required this.sharedUrl});

  final String sharedUrl;

  /// Convenience to present the sheet.
  static Future<void> show(BuildContext context, String sharedUrl) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShareCaptureSheet(sharedUrl: sharedUrl),
    );
  }

  @override
  State<ShareCaptureSheet> createState() => _ShareCaptureSheetState();
}

class _ShareCaptureSheetState extends State<ShareCaptureSheet> {
  @override
  Widget build(BuildContext context) {
    // TODO: compact form pre-filled with widget.sharedUrl + save action.
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Save shared link'),
    );
  }
}
