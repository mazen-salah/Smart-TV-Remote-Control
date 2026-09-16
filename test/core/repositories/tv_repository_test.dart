import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/core/services/known_tvs_storage.dart';
import 'package:remote/core/services/tv_token_storage.dart';
import 'package:remote/core/services/wake_on_lan_service.dart';
import 'package:remote/services/mdns/bonjour_discovery_service.dart';
import 'package:remote/services/upnp/ssdp_discovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSsdp extends Mock implements SsdpDiscoveryService {}

class _MockBonjour extends Mock implements BonjourDiscoveryService {}

class _MockWol extends Mock implements WakeOnLanService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TvTokenStorage tokens;
  late KnownTvsStorage knownTvs;
  late _MockSsdp ssdp;
  late _MockBonjour bonjour;
  late _MockWol wol;
  late TvRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tokens = TvTokenStorage(prefs);
    knownTvs = KnownTvsStorage(prefs);
    ssdp = _MockSsdp();
    bonjour = _MockBonjour();
    wol = _MockWol();
    when(() => ssdp.discoverAll()).thenAnswer((_) async => <TVDevice>[]);
    when(() => bonjour.discoverAll()).thenAnswer((_) async => <TVDevice>[]);
    repository = TvRepository(
      tokenStorage: tokens,
      knownTvsStorage: knownTvs,
      wakeOnLanService: wol,
      ssdpDiscoveryService: ssdp,
      bonjourDiscoveryService: bonjour,
    );
  });

  group('discoverAll', () {
    test('merges both sweeps by host, keeping the richer record', () async {
      when(() => ssdp.discoverAll()).thenAnswer(
        (_) async => [
          TVDevice(
            host: '10.0.0.5',
            deviceName: 'Living Room',
            manufacturer: 'Samsung',
          ),
        ],
      );
      when(() => bonjour.discoverAll()).thenAnswer(
        (_) async => [
          TVDevice(host: '10.0.0.5', modelName: 'QN65Q80C'),
          TVDevice(host: '10.0.0.9', deviceName: 'Bedroom'),
        ],
      );

      final devices = await repository.discoverAll();

      expect(devices, hasLength(2));
      final merged = devices.firstWhere((d) => d.host == '10.0.0.5');
      expect(merged.deviceName, 'Living Room');
      expect(merged.modelName, 'QN65Q80C');
    });

    test('survives one sweep failing', () async {
      when(() => ssdp.discoverAll()).thenThrow(Exception('no multicast'));
      when(
        () => bonjour.discoverAll(),
      ).thenAnswer((_) async => [TVDevice(host: '10.0.0.9')]);

      expect(await repository.discoverAll(), hasLength(1));
    });
  });

  group('forget', () {
    test('clears credentials saved under both the host and the MAC', () async {
      final device = TVDevice(host: '10.0.0.5', mac: 'AA:BB:CC');
      // A Samsung token saved before the MAC was known, and one after.
      await tokens.save('10.0.0.5', 'host-token');
      await tokens.save('AA:BB:CC', 'mac-token');
      // LG keys and pinned certificates use their own prefixes.
      await tokens.save('lg:10.0.0.5', 'host-key');
      await tokens.save('cert:lg:AA:BB:CC', 'a' * 64);
      await knownTvs.save(device);
      await knownTvs.saveLastUsed(device);

      await repository.forget(device);

      expect(tokens.load('10.0.0.5'), isNull);
      expect(tokens.load('AA:BB:CC'), isNull);
      expect(tokens.load('lg:10.0.0.5'), isNull);
      expect(tokens.load('cert:lg:AA:BB:CC'), isNull);
      expect(knownTvs.loadAll(), isEmpty);
      expect(knownTvs.loadLastUsed(), isNull);
    });

    test('leaves other TVs alone', () async {
      final keep = TVDevice(host: '10.0.0.9', mac: 'DD:EE:FF');
      await tokens.save('DD:EE:FF', 'keep-me');
      await knownTvs.save(keep);

      await repository.forget(TVDevice(host: '10.0.0.5', mac: 'AA:BB:CC'));

      expect(tokens.load('DD:EE:FF'), 'keep-me');
      expect(knownTvs.loadAll(), hasLength(1));
    });
  });

  group('connect', () {
    setUp(() {
      // The test binding installs a mock HttpClient; these tests need a
      // real socket so the connection genuinely fails the way a TV would.
      HttpOverrides.global = null;
    });

    // 203.0.113.0/24 is reserved for documentation and is not routable, so
    // the connection fails without waiting on a real host.
    final unreachable = TVDevice(
      host: '203.0.113.1',
      mac: 'AA:BB:CC:DD:EE:FF',
      manufacturer: 'LG',
    );

    test('wakes a known TV that cannot be reached, then gives up', () async {
      when(
        () => wol.wake(mac: any(named: 'mac')),
      ).thenAnswer((_) async => false);

      await expectLater(repository.connect(unreachable), throwsA(anything));

      verify(() => wol.wake(mac: 'AA:BB:CC:DD:EE:FF')).called(1);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('does not send a magic packet when no MAC is known', () async {
      final noMac = TVDevice(host: '203.0.113.2', manufacturer: 'LG');

      await expectLater(repository.connect(noMac), throwsA(anything));

      verifyNever(() => wol.wake(mac: any(named: 'mac')));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
