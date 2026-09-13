import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/device_discovery/device_discovery_event.dart';
import 'package:remote/blocs/device_discovery/device_discovery_state.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';

export 'device_discovery_event.dart';
export 'device_discovery_state.dart';

class DeviceDiscoveryBloc
    extends Bloc<DeviceDiscoveryEvent, DeviceDiscoveryState> {
  DeviceDiscoveryBloc({required TvRepository repository})
      : _repository = repository,
        super(const DeviceDiscoveryState()) {
    on<DiscoveryStarted>(_onDiscoveryStarted);
    on<DiscoveryRefreshRequested>(_onDiscoveryStarted);
    on<ManualDeviceAdded>(_onManualDeviceAdded);
  }

  final TvRepository _repository;

  Future<void> _onDiscoveryStarted(
    DeviceDiscoveryEvent event,
    Emitter<DeviceDiscoveryState> emit,
  ) async {
    final known = _repository.knownTvs();
    final lastUsed = _repository.lastUsed();
    emit(
      state.copyWith(
        status: DiscoveryStatus.scanning,
        knownTvs: known,
        lastUsed: lastUsed,
        clearError: true,
      ),
    );

    try {
      final discovered = await _repository.discoverAll();
      // Merge known + discovered, dedupe by (host, mac) via TVDevice.==.
      final merged = <TVDevice>{...known, ...discovered}.toList();
      emit(
        state.copyWith(
          status:
              merged.isEmpty ? DiscoveryStatus.empty : DiscoveryStatus.success,
          devices: merged,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onManualDeviceAdded(
    ManualDeviceAdded event,
    Emitter<DeviceDiscoveryState> emit,
  ) async {
    final device = TVDevice(
      host: event.host,
      deviceName: event.name ?? event.host,
      manufacturer: event.brand.manufacturer,
    );
    final next = [...state.devices.where((d) => d.host != device.host), device];
    emit(
      state.copyWith(
        status: DiscoveryStatus.success,
        devices: next,
      ),
    );
  }
}
