import 'package:flutter/services.dart';

/// Listens for URLs shared into the app via the Android share sheet.
///
/// Backed by a small native bridge in MainActivity (Android) rather than a
/// third-party plugin, since we only need shared URLs. Handles both the
/// cold-start case (app launched by a share) and the warm case (app already
/// running). Emitted URLs are routed to the share-capture bottom sheet.
class ShareIntentService {
  static const MethodChannel _method = MethodChannel(
    'app.webnovel_tracker/share',
  );
  static const EventChannel _events = EventChannel(
    'app.webnovel_tracker/share/events',
  );

  /// Returns the URL the app was cold-launched with via a share, if any.
  static Future<String?> initialSharedUrl() {
    return _method.invokeMethod<String>('getInitialLink');
  }

  /// Stream of URLs shared while the app is already running.
  static Stream<String> get sharedUrlStream =>
      _events.receiveBroadcastStream().cast<String>();

  /// Tells the native side we've consumed the initial share (call after handling).
  static Future<void> reset() {
    return _method.invokeMethod<void>('reset');
  }
}
