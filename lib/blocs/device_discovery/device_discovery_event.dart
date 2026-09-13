import 'package:equatable/equatable.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';

sealed class DeviceDiscoveryEvent extends Equatable {
  const DeviceDiscoveryEvent();

  @override
  List<Object?> get props => const [];
}

final class DiscoveryStarted extends DeviceDiscoveryEvent {
  const DiscoveryStarted();
}

final class DiscoveryRefreshRequested extends DeviceDiscoveryEvent {
  const DiscoveryRefreshRequested();
}

final class ManualDeviceAdded extends DeviceDiscoveryEvent {
  const ManualDeviceAdded({
    required this.host,
    this.name,
    this.brand = TvBrand.samsung,
  });
  final String host;
  final String? name;
  final TvBrand brand;

  @override
  List<Object?> get props => [host, name, brand];
}

/// The user removed [device] from the picker (and its pairing).
final class DeviceForgotten extends DeviceDiscoveryEvent {
  const DeviceForgotten(this.device);
  final TVDevice device;

  @override
  List<Object?> get props => [device];
}
