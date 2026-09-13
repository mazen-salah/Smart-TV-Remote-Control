import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_device.dart';

void main() {
  group('TVDevice', () {
    test('equality is based on host + mac, ignoring other fields', () {
      final a = TVDevice(
        host: '10.0.0.5',
        mac: 'AA:BB:CC:DD:EE:FF',
        deviceName: 'Living Room',
      );
      final b = TVDevice(
        host: '10.0.0.5',
        mac: 'AA:BB:CC:DD:EE:FF',
        deviceName: 'Different Name',
      );
      final c = TVDevice(
        host: '10.0.0.6',
        mac: 'AA:BB:CC:DD:EE:FF',
        deviceName: 'Living Room',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith overrides only the requested fields', () {
      final original = TVDevice(
        host: '10.0.0.5',
        mac: 'AA',
        deviceName: 'Old',
        modelName: 'M1',
      );
      final copy = original.copyWith(deviceName: 'New');

      expect(copy.host, '10.0.0.5');
      expect(copy.mac, 'AA');
      expect(copy.deviceName, 'New');
      expect(copy.modelName, 'M1');
    });

    test('displayName falls through deviceName -> modelName -> Unknown TV', () {
      expect(
        TVDevice(deviceName: 'Bedroom', modelName: 'UN55').displayName,
        'Bedroom',
      );
      expect(TVDevice(modelName: 'UN55').displayName, 'UN55');
      expect(TVDevice().displayName, 'Unknown TV');
    });
  });
}
