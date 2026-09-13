import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/services/known_tvs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KnownTvsStorage', () {
    test('loadAll returns empty list when nothing is stored', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = KnownTvsStorage(prefs);

      expect(storage.loadAll(), isEmpty);
    });

    test('save persists a device and round-trips through loadAll', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = KnownTvsStorage(prefs);
      final device =
          TVDevice(host: '10.0.0.5', mac: 'AA', deviceName: 'Living Room');

      await storage.save(device);
      final loaded = storage.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded.first.host, '10.0.0.5');
      expect(loaded.first.deviceName, 'Living Room');
    });

    test('save replaces a device with same host + mac instead of duplicating',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = KnownTvsStorage(prefs);

      await storage
          .save(TVDevice(host: '10.0.0.5', mac: 'AA', deviceName: 'Old'));
      await storage
          .save(TVDevice(host: '10.0.0.5', mac: 'AA', deviceName: 'New'));

      final loaded = storage.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.deviceName, 'New');
    });

    test('remove deletes the matching device', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = KnownTvsStorage(prefs);
      await storage.save(TVDevice(host: '10.0.0.5', mac: 'AA'));
      await storage.save(TVDevice(host: '10.0.0.6', mac: 'BB'));

      await storage.remove(TVDevice(host: '10.0.0.5', mac: 'AA'));

      final loaded = storage.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.host, '10.0.0.6');
    });

    test('last-used save/load/clear lifecycle', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = KnownTvsStorage(prefs);
      final device =
          TVDevice(host: '10.0.0.5', mac: 'AA', deviceName: 'Bedroom');

      expect(storage.loadLastUsed(), isNull);

      await storage.saveLastUsed(device);
      expect(storage.loadLastUsed()?.deviceName, 'Bedroom');

      await storage.clearLastUsed();
      expect(storage.loadLastUsed(), isNull);
    });

    test('loadAll returns empty list when stored JSON is corrupt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('known_tvs', 'not-valid-json');
      final storage = KnownTvsStorage(prefs);

      expect(storage.loadAll(), isEmpty);
    });
  });
}
