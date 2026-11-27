import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/services/hardware_volume_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/volume_keys');
  final platformCalls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// What the platform side would send for one press of the rocker.
  Future<void> pressKey(String direction) => messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('onVolumeKey', direction),
    ),
    (_) {},
  );

  void answerPlatform({bool failWithMissingPlugin = false}) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      platformCalls.add(call);
      if (failWithMissingPlugin) throw MissingPluginException();
      return null;
    });
  }

  setUp(() {
    platformCalls.clear();
    answerPlatform();
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('HardwareVolumeKeys', () {
    test('reports unsupported where there is no platform support', () async {
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: false);

      expect(await keys.start((_) {}), isFalse);
      expect(keys.isCapturing, isFalse);
      expect(platformCalls, isEmpty);
    });

    test('asks the platform to start and reports success', () async {
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);

      expect(await keys.start((_) {}), isTrue);
      expect(platformCalls.map((c) => c.method), ['start']);
      expect(keys.isCapturing, isTrue);
    });

    test('forwards both directions to the callback', () async {
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);
      final presses = <VolumeKeyDirection>[];
      await keys.start(presses.add);

      await pressKey('up');
      await pressKey('down');

      expect(presses, [VolumeKeyDirection.up, VolumeKeyDirection.down]);
    });

    test('ignores anything that is not up or down', () async {
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);
      final presses = <VolumeKeyDirection>[];
      await keys.start(presses.add);

      await pressKey('mute');
      await pressKey('');

      expect(presses, isEmpty);
    });

    test('stop hands the keys back to the phone', () async {
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);
      final presses = <VolumeKeyDirection>[];
      await keys.start(presses.add);

      await keys.stop();
      await pressKey('up');

      expect(presses, isEmpty);
      expect(keys.isCapturing, isFalse);
      expect(platformCalls.map((c) => c.method), ['start', 'stop']);
    });

    test(
      'a second start replaces the callback without starting twice',
      () async {
        final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);
        final first = <VolumeKeyDirection>[];
        final second = <VolumeKeyDirection>[];
        await keys.start(first.add);

        await keys.start(second.add);
        await pressKey('up');

        expect(platformCalls.map((c) => c.method), ['start']);
        expect(first, isEmpty);
        expect(second, [VolumeKeyDirection.up]);
      },
    );

    test('survives a platform without the channel', () async {
      answerPlatform(failWithMissingPlugin: true);
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);

      expect(await keys.start((_) {}), isFalse);
      expect(keys.isCapturing, isFalse);
    });

    test('stop without start touches nothing', () async {
      final keys = HardwareVolumeKeys(channel: channel, isAndroid: true);

      await keys.stop();

      expect(platformCalls, isEmpty);
    });
  });
}
