import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/device_discovery/device_discovery_bloc.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';

class _MockTvRepository extends Mock implements TvRepository {}

void main() {
  late _MockTvRepository repository;

  setUp(() {
    repository = _MockTvRepository();
  });

  group('DeviceDiscoveryBloc', () {
    blocTest<DeviceDiscoveryBloc, DeviceDiscoveryState>(
      'DiscoveryStarted: scanning -> success with merged devices',
      build: () {
        final known = [
          TVDevice(host: '10.0.0.5', mac: 'AA', deviceName: 'Known'),
        ];
        final discovered = [
          TVDevice(host: '10.0.0.6', mac: 'BB', deviceName: 'New'),
        ];
        when(() => repository.knownTvs()).thenReturn(known);
        when(() => repository.lastUsed()).thenReturn(known.first);
        when(
          () => repository.discoverAll(),
        ).thenAnswer((_) async => discovered);
        return DeviceDiscoveryBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const DiscoveryStarted()),
      expect: () => [
        isA<DeviceDiscoveryState>()
            .having((s) => s.status, 'status', DiscoveryStatus.scanning)
            .having((s) => s.knownTvs.length, 'known count', 1)
            .having((s) => s.lastUsed?.host, 'lastUsed', '10.0.0.5'),
        isA<DeviceDiscoveryState>()
            .having((s) => s.status, 'status', DiscoveryStatus.success)
            .having((s) => s.devices.length, 'devices count', 2),
      ],
    );

    blocTest<DeviceDiscoveryBloc, DeviceDiscoveryState>(
      'DiscoveryStarted: scanning -> empty when no devices found',
      build: () {
        when(() => repository.knownTvs()).thenReturn(const []);
        when(() => repository.lastUsed()).thenReturn(null);
        when(() => repository.discoverAll()).thenAnswer((_) async => const []);
        return DeviceDiscoveryBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const DiscoveryStarted()),
      expect: () => [
        isA<DeviceDiscoveryState>().having(
          (s) => s.status,
          'status',
          DiscoveryStatus.scanning,
        ),
        isA<DeviceDiscoveryState>()
            .having((s) => s.status, 'status', DiscoveryStatus.empty)
            .having((s) => s.devices, 'devices', isEmpty),
      ],
    );

    blocTest<DeviceDiscoveryBloc, DeviceDiscoveryState>(
      'DiscoveryStarted: emits error when discoverAll throws',
      build: () {
        when(() => repository.knownTvs()).thenReturn(const []);
        when(() => repository.lastUsed()).thenReturn(null);
        when(
          () => repository.discoverAll(),
        ).thenThrow(Exception('mDNS failed'));
        return DeviceDiscoveryBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const DiscoveryRefreshRequested()),
      expect: () => [
        isA<DeviceDiscoveryState>().having(
          (s) => s.status,
          'status',
          DiscoveryStatus.scanning,
        ),
        isA<DeviceDiscoveryState>()
            .having((s) => s.status, 'status', DiscoveryStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('mDNS failed'),
            ),
      ],
    );

    blocTest<DeviceDiscoveryBloc, DeviceDiscoveryState>(
      'ManualDeviceAdded: appends a manual device without touching repository',
      build: () => DeviceDiscoveryBloc(repository: repository),
      act: (bloc) => bloc.add(
        const ManualDeviceAdded(host: '192.168.1.99', name: 'Office TV'),
      ),
      expect: () => [
        isA<DeviceDiscoveryState>()
            .having((s) => s.status, 'status', DiscoveryStatus.success)
            .having((s) => s.devices.length, 'devices count', 1)
            .having((s) => s.devices.first.host, 'host', '192.168.1.99')
            .having(
              (s) => s.devices.first.deviceName,
              'deviceName',
              'Office TV',
            ),
      ],
      verify: (_) {
        verifyNever(() => repository.discoverAll());
      },
    );

    blocTest<DeviceDiscoveryBloc, DeviceDiscoveryState>(
      'ManualDeviceAdded: tags the device with the chosen brand',
      build: () => DeviceDiscoveryBloc(repository: repository),
      act: (bloc) => bloc.add(
        const ManualDeviceAdded(host: '192.168.1.57', brand: TvBrand.lg),
      ),
      expect: () => [
        isA<DeviceDiscoveryState>().having(
          (s) => s.devices.single.manufacturer,
          'manufacturer',
          'LG',
        ),
      ],
    );
  });
}
