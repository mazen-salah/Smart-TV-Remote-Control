import 'package:equatable/equatable.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_device.dart';

enum TvConnectionStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}

class TvConnectionState extends Equatable {
  const TvConnectionState({
    this.status = TvConnectionStatus.idle,
    this.device,
    this.disconnectionType,
    this.errorMessage,
  });

  const TvConnectionState.idle() : this();

  final TvConnectionStatus status;
  final TVDevice? device;
  final DisconnectionType? disconnectionType;
  final String? errorMessage;

  bool get isConnected => status == TvConnectionStatus.connected;
  bool get isConnecting =>
      status == TvConnectionStatus.connecting ||
      status == TvConnectionStatus.reconnecting;

  TvConnectionState copyWith({
    TvConnectionStatus? status,
    TVDevice? device,
    DisconnectionType? disconnectionType,
    String? errorMessage,
    bool clearDisconnection = false,
    bool clearError = false,
  }) {
    return TvConnectionState(
      status: status ?? this.status,
      device: device ?? this.device,
      disconnectionType: clearDisconnection
          ? null
          : disconnectionType ?? this.disconnectionType,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, device, disconnectionType, errorMessage];
}
