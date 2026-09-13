import 'package:equatable/equatable.dart';
import 'package:remote/core/models/tv_brand.dart';

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
