import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/roku/roku_tv_service.dart';

import 'fake_roku.dart';

void main() {
  late FakeRoku roku;

  setUp(() async {
    roku = await FakeRoku.start();
  });

  tearDown(() => roku.close());

  RokuTvService serviceFor({String? host, int? port}) =>
      RokuTvService(host: host ?? roku.host, port: port ?? roku.port);

  group('connect', () {
    test('reads the device description', () async {
      final service = serviceFor();

      await service.connect();

      expect(service.isConnected, isTrue);
      expect(service.deviceName, 'Living Room TV');
      expect(service.modelName, 'Roku Ultra');
      expect(service.mac, 'd0:4d:2c:00:11:22');
      expect(service.serialNumber, 'X0123456789AB');
      expect(roku.requests, ['/query/device-info']);
      service.disconnect();
    });

    test(
      'falls back to the friendly name when the user renamed nothing',
      () async {
        roku.deviceInfo = FakeRoku.defaultDeviceInfo.replaceAll(
          '<user-device-name>Living Room TV</user-device-name>',
          '<user-device-name></user-device-name>',
        );
        final service = serviceFor();

        await service.connect();

        expect(service.deviceName, 'Roku Ultra - Living Room');
        service.disconnect();
      },
    );

    test('reports an unreachable device', () async {
      // Bind and release a port so nothing is listening there.
      final reserved = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = reserved.port;
      await reserved.close();
      final service = serviceFor(port: deadPort);

      await expectLater(service.connect(), throwsA(isA<SocketException>()));
      expect(service.isConnected, isFalse);
    });

    test('survives a device description it cannot read', () async {
      roku.deviceInfo = '<device-info><model-name>oops';
      final service = serviceFor();

      await expectLater(service.connect(), throwsA(isA<FormatException>()));
      expect(service.isConnected, isFalse);
    });

    test('ensureConnection only fetches once', () async {
      final service = serviceFor();

      await service.ensureConnection();
      await service.ensureConnection();

      expect(
        roku.requests.where((p) => p == '/query/device-info'),
        hasLength(1),
      );
      service.disconnect();
    });
  });

  group('keys', () {
    test('posts the ECP name for a remote key', () async {
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_VOLUP);
      await service.sendKey(KeyCodes.KEY_UP);
      await service.sendKey(KeyCodes.KEY_ENTER);
      await service.sendKey(KeyCodes.KEY_5);

      expect(roku.requests, [
        '/query/device-info',
        '/keypress/VolumeUp',
        '/keypress/Up',
        '/keypress/Select',
        '/keypress/Lit_5',
      ]);
      service.disconnect();
    });

    test('power turns the device off', () async {
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_POWER);

      expect(roku.requests.last, '/keypress/PowerOff');
      service.disconnect();
    });

    test('a key Roku does not have is ignored', () async {
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_RED);

      expect(roku.requests, ['/query/device-info']);
      service.disconnect();
    });

    test(
      'leaves the device alone when the Roku does not accept the key',
      () async {
        roku.postStatus = 404;
        final service = serviceFor();
        await service.connect();

        await expectLater(
          service.sendKey(KeyCodes.KEY_HOME),
          throwsA(isA<HttpException>()),
        );
        // A 404 is the device talking, not a dead connection.
        expect(service.isConnected, isTrue);
        service.disconnect();
      },
    );

    test('launches an app by channel id', () async {
      final service = serviceFor();
      await service.connect();

      await service.launchApp('12');

      expect(roku.requests.last, '/launch/12');
      service.disconnect();
    });
  });

  group('connection state', () {
    test('reports a device that disappears mid-session', () async {
      final service = serviceFor();
      await service.connect();
      DisconnectionType? reason;
      service.onDisconnected = (type) => reason = type;

      await roku.close();
      // package:http wraps the dead socket, so the failure can surface as
      // either an http error or a raw socket error.
      await expectLater(
        service.sendKey(KeyCodes.KEY_HOME),
        throwsA(anyOf(isA<SocketException>(), isA<http.ClientException>())),
      );

      expect(reason, DisconnectionType.networkError);
      expect(service.isConnected, isFalse);
    });

    test('does not report a device that was never reachable', () async {
      final reserved = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = reserved.port;
      await reserved.close();
      final service = serviceFor(port: deadPort);
      DisconnectionType? reason;
      service.onDisconnected = (type) => reason = type;

      await expectLater(service.connect(), throwsA(isA<SocketException>()));

      expect(reason, isNull);
    });
  });
}
