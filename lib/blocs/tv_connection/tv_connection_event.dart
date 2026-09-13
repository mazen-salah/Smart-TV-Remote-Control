import 'package:equatable/equatable.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/tv_device.dart';

sealed class TvConnectionEvent extends Equatable {
  const TvConnectionEvent();

  @override
  List<Object?> get props => const [];
}

final class TvConnectRequested extends TvConnectionEvent {
  const TvConnectRequested(this.device);
  final TVDevice device;

  @override
  List<Object?> get props => [device];
}

final class TvDisconnectRequested extends TvConnectionEvent {
  const TvDisconnectRequested();
}

final class TvSendKeyRequested extends TvConnectionEvent {
  const TvSendKeyRequested(this.key);
  final KeyCodes key;

  @override
  List<Object?> get props => [key];
}

/// Forget [device], or the currently connected TV when null.
final class TvForgetRequested extends TvConnectionEvent {
  const TvForgetRequested({this.device});
  final TVDevice? device;

  @override
  List<Object?> get props => [device];
}

final class TvDisconnectionDetected extends TvConnectionEvent {
  const TvDisconnectionDetected(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}
