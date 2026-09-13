import 'package:equatable/equatable.dart';
import 'package:remote/core/models/tv_device.dart';

enum DiscoveryStatus { idle, scanning, success, empty, error }

class DeviceDiscoveryState extends Equatable {
  const DeviceDiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.devices = const [],
    this.knownTvs = const [],
    this.lastUsed,
    this.errorMessage,
  });

  final DiscoveryStatus status;
  final List<TVDevice> devices;
  final List<TVDevice> knownTvs;
  final TVDevice? lastUsed;
  final String? errorMessage;

  DeviceDiscoveryState copyWith({
    DiscoveryStatus? status,
    List<TVDevice>? devices,
    List<TVDevice>? knownTvs,
    TVDevice? lastUsed,
    String? errorMessage,
    bool clearError = false,
    bool clearLastUsed = false,
  }) {
    return DeviceDiscoveryState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      knownTvs: knownTvs ?? this.knownTvs,
      lastUsed: clearLastUsed ? null : lastUsed ?? this.lastUsed,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        devices,
        knownTvs,
        lastUsed,
        errorMessage,
      ];
}
