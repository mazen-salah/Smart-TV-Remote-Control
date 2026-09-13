import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_device.dart';

void main() {
  group('TVDevice.mergeByHost', () {
    test('collapses a known entry with MAC and a discovered one without', () {
      final known = TVDevice(
        host: '192.168.1.42',
        mac: 'AA:BB',
        deviceName: 'Living Room',
      );
      final discovered = TVDevice(
        host: '192.168.1.42',
        modelName: 'QN65Q80C',
        manufacturer: 'Samsung',
      );
      final merged = TVDevice.mergeByHost([known, discovered]);
      expect(merged, hasLength(1));
      expect(merged.single.mac, 'AA:BB');
      expect(merged.single.deviceName, 'Living Room');
      expect(merged.single.modelName, 'QN65Q80C');
      expect(merged.single.manufacturer, 'Samsung');
    });

    test('keeps distinct hosts and hostless entries', () {
      final merged = TVDevice.mergeByHost([
        TVDevice(host: '10.0.0.1'),
        TVDevice(host: '10.0.0.2'),
        TVDevice(deviceName: 'no host'),
      ]);
      expect(merged, hasLength(3));
    });
  });
}
