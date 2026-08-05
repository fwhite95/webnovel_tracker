import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_capture_state.freezed.dart';

/// [pendingUrl] is non-null exactly while a shared URL is waiting to be shown
/// in the capture sheet; cleared again once the sheet has been handled.
@freezed
abstract class ShareCaptureState with _$ShareCaptureState {
  const factory ShareCaptureState({String? pendingUrl}) = _ShareCaptureState;
}
