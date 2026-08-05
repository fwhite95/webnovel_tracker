import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webnovel_tracker/features/share_capture/bloc/share_capture_event.dart';
import 'package:webnovel_tracker/features/share_capture/bloc/share_capture_state.dart';
import 'package:webnovel_tracker/services/share_intent_service.dart';

/// Watches [ShareIntentService] for URLs shared into the app and parks the most
/// recent one in [ShareCaptureState.pendingUrl] for the capture sheet to pick
/// up. Saving is the sheet's job — this bloc only routes the incoming URL.
class ShareCaptureBloc extends Bloc<ShareCaptureEvent, ShareCaptureState> {
  ShareCaptureBloc() : super(const ShareCaptureState()) {
    on<ShareCaptureStarted>(_onStarted);
    on<ShareCaptureUrlReceived>(_onUrlReceived);
    on<ShareCaptureHandled>(_onHandled);
  }

  StreamSubscription<String>? _subscription;

  Future<void> _onStarted(
    ShareCaptureStarted event,
    Emitter<ShareCaptureState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = ShareIntentService.sharedUrlStream.listen(
      (url) => add(ShareCaptureEvent.urlReceived(url)),
      onError: (Object err) => debugPrint('share stream error: $err'),
    );

    // Cold start: the app was launched by the share itself.
    final initial = await ShareIntentService.initialSharedUrl();
    if (initial != null && initial.isNotEmpty) {
      add(ShareCaptureEvent.urlReceived(initial));
    }
  }

  void _onUrlReceived(
    ShareCaptureUrlReceived event,
    Emitter<ShareCaptureState> emit,
  ) {
    final url = event.url.trim();
    if (url.isEmpty) return;
    emit(ShareCaptureState(pendingUrl: url));
  }

  Future<void> _onHandled(
    ShareCaptureHandled event,
    Emitter<ShareCaptureState> emit,
  ) async {
    emit(const ShareCaptureState());
    // Clears the native-side initial link too, so a warm restart doesn't
    // re-present a URL the user already dealt with.
    await ShareIntentService.reset();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
