import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di.dart';
import 'features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'features/entries/bloc/entry_list/entry_list_event.dart';
import 'features/entries/view/home_screen.dart';
import 'services/share_intent_service.dart';

class WebNovelTrackerApp extends StatefulWidget {
  const WebNovelTrackerApp({super.key});

  @override
  State<WebNovelTrackerApp> createState() => _WebNovelTrackerAppState();
}

/// Root widget: theme + top-level bloc providers.
class _WebNovelTrackerAppState extends State<WebNovelTrackerApp> {
  StreamSubscription<String>? _intentSub;

  @override
  void initState() {
    super.initState();

    // URLs shared into the app while it's already running.
    _intentSub = ShareIntentService.sharedUrlStream.listen(
      _handleSharedUrl,
      onError: (Object err) => debugPrint('share stream error: $err'),
    );

    // The URL the app was cold-launched with via a share, if any.
    ShareIntentService.initialSharedUrl().then((url) {
      if (url != null && url.isNotEmpty) {
        _handleSharedUrl(url);
        ShareIntentService.reset();
      }
    });
  }

  void _handleSharedUrl(String url) {
    // TODO: open the share-capture bottom sheet pre-filled with [url].
    debugPrint('shared url: $url');
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Novel Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) =>
            getIt<EntryListBloc>()..add(const EntryListEvent.started()),
        child: const HomeScreen(),
      ),
    );
  }
}
