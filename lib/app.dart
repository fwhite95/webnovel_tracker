import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/core/di.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_bloc.dart';
import 'package:webnovel_tracker/features/entries/bloc/entry_list/entry_list_event.dart';
import 'package:webnovel_tracker/features/entries/view/home_screen.dart';
import 'package:webnovel_tracker/features/entries/view/new_entry_bottom_sheet.dart';
import 'package:webnovel_tracker/features/share_capture/bloc/share_capture_bloc.dart';
import 'package:webnovel_tracker/features/share_capture/bloc/share_capture_event.dart';
import 'package:webnovel_tracker/features/share_capture/bloc/share_capture_state.dart';

class WebNovelTrackerApp extends StatelessWidget {
  const WebNovelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ShareCaptureBloc>()..add(const ShareCaptureEvent.started()),
      child: MaterialApp(
        title: 'Web Novel Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: BlocProvider(
          create: (_) =>
              getIt<EntryListBloc>()..add(const EntryListEvent.started()),
          // Below MaterialApp, so there's a Navigator to present the sheet with.
          child: BlocListener<ShareCaptureBloc, ShareCaptureState>(
            listenWhen: (prev, curr) => curr.pendingUrl != null,
            listener: (context, state) async {
              await NewEntryBottomSheet.show(
                context,
                initialUrl: state.pendingUrl,
              );
              if (!context.mounted) return;
              context.read<ShareCaptureBloc>().add(
                const ShareCaptureEvent.handled(),
              );
            },
            child: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
