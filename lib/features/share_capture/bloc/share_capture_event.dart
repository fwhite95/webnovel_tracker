import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_capture_event.freezed.dart';

@freezed
sealed class ShareCaptureEvent with _$ShareCaptureEvent {
  /// Begin listening. Dispatched once the Navigator exists (see [WebNovelTrackerApp]).
  const factory ShareCaptureEvent.started() = ShareCaptureStarted;

  /// Internal: a URL arrived from [ShareIntentService].
  const factory ShareCaptureEvent.urlReceived(String url) =
      ShareCaptureUrlReceived;

  /// The sheet was shown and dismissed — clear the pending URL.
  const factory ShareCaptureEvent.handled() = ShareCaptureHandled;
}
