import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/sony/sony_tv_service.dart';

import 'fake_sony.dart';

void main() {
  late FakeSony sony;

  setUp(() async {
    sony = await FakeSony.start();
  });

  tearDown(() => sony.close());

  SonyTvService serviceFor({String? psk, int? port}) => SonyTvService(
    host: sony.host,
    port: port ?? sony.port,
    preSharedKey: psk,
  );

  group('connect', () {
    test('reads the system information', () async {
      final service = serviceFor();

      await service.connect();

      expect(service.isConnected, isTrue);
      expect(service.deviceName, 'BRAVIA');
      expect(service.modelName, 'KD-55XH9096');
      expect(service.mac, 'AC:9B:0A:11:22:33');
      expect(service.serialNumber, '1234567');
      service.disconnect();
    });

    test('asks the TV for its own button codes', () async {
      sony.remoteCodes = {'VolumeUp': 'TV-SPECIFIC-CODE'};
      final service = serviceFor();

      await service.connect();

      expect(service.remoteCodes, {'VolumeUp': 'TV-SPECIFIC-CODE'});
      expect(sony.requests.map((r) => r.method), [
        'getSystemInformation',
        'getRemoteControllerInfo',
      ]);
      service.disconnect();
    });

    test('connects even when the TV will not list its buttons', () async {
      sony.remoteCodesStatus = 500;
      final service = serviceFor();

      await service.connect();

      expect(service.isConnected, isTrue);
      expect(service.remoteCodes, isEmpty);
      service.disconnect();
    });

    test('reports a pre-shared key the TV does not accept', () async {
      sony = await FakeSony.start(preSharedKey: 'right-key');
      final service = serviceFor(psk: 'wrong-key');

      await expectLater(service.connect(), throwsA(isA<SonyAuthException>()));
      expect(service.isConnected, isFalse);
      service.disconnect();
    });

    test('sends the key the TV was configured with', () async {
      sony = await FakeSony.start(preSharedKey: 'right-key');
      final service = serviceFor(psk: 'right-key');

      await service.connect();

      expect(service.isConnected, isTrue);
      expect(sony.requests.first.auth, 'right-key');
      service.disconnect();
    });

    test('reports an unreachable TV', () async {
      final reserved = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = reserved.port;
      await reserved.close();
      final service = serviceFor(port: deadPort);

      await expectLater(service.connect(), throwsA(isA<Exception>()));
      expect(service.isConnected, isFalse);
    });
  });

  group('keys', () {
    test('presses a button with the documented IRCC code', () async {
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_VOLUP);
      await service.sendKey(KeyCodes.KEY_ENTER);

      final presses = sony.requests
          .where((r) => r.path == '/sony/IRCC')
          .toList();
      expect(presses, hasLength(2));
      expect(presses.first.irccCode, 'AAAAAQAAAAEAAAASAw==');
      expect(presses.last.irccCode, 'AAAAAQAAAAEAAABlAw==');
      expect(
        presses.first.soapAction,
        '"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"',
      );
      service.disconnect();
    });

    test('prefers the code the TV reports over the documented one', () async {
      sony.remoteCodes = {'VolumeUp': 'TV-CODE'};
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_VOLUP);

      expect(
        sony.requests.lastWhere((r) => r.path == '/sony/IRCC').irccCode,
        'TV-CODE',
      );
      service.disconnect();
    });

    test('power uses PowerOff, since an off Bravia is not reachable', () async {
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_POWER);

      expect(
        sony.requests.lastWhere((r) => r.path == '/sony/IRCC').irccCode,
        'AAAAAQAAAAEAAAAvAw==',
      );
      service.disconnect();
    });

    test('a key the set does not know is not sent at all', () async {
      final service = serviceFor();
      await service.connect();

      // Rewind has no documented code; without one from the TV it is dropped
      // rather than guessed.
      await service.sendKey(KeyCodes.KEY_REWIND);

      expect(sony.requests.where((r) => r.path == '/sony/IRCC'), isEmpty);
      service.disconnect();
    });

    test('sends a code the TV reported for a key without a fallback', () async {
      sony.remoteCodes = {'Rewind': 'TV-REWIND'};
      final service = serviceFor();
      await service.connect();

      await service.sendKey(KeyCodes.KEY_REWIND);

      expect(
        sony.requests.lastWhere((r) => r.path == '/sony/IRCC').irccCode,
        'TV-REWIND',
      );
      service.disconnect();
    });

    test('reports a key press the TV rejects', () async {
      sony = await FakeSony.start(preSharedKey: 'right-key');
      final service = serviceFor(psk: 'right-key');
      await service.connect();
      sony.preSharedKey = 'changed-on-the-tv';

      await expectLater(
        service.sendKey(KeyCodes.KEY_HOME),
        throwsA(isA<SonyAuthException>()),
      );
      service.disconnect();
    });
  });

  group('connection state', () {
    test('forgets the reported codes when disconnected', () async {
      sony.remoteCodes = {'VolumeUp': 'TV-CODE'};
      final service = serviceFor();
      await service.connect();

      service.disconnect();

      expect(service.remoteCodes, isEmpty);
    });

    test('reports a TV that disappears mid-session', () async {
      final service = serviceFor();
      await service.connect();
      DisconnectionType? reason;
      service.onDisconnected = (type) => reason = type;

      await sony.close();
      await expectLater(
        service.sendKey(KeyCodes.KEY_HOME),
        throwsA(anyOf(isA<SocketException>(), isA<http.ClientException>())),
      );

      expect(reason, DisconnectionType.networkError);
      expect(service.isConnected, isFalse);
    });

    test('does not report a TV that was never reachable', () async {
      final reserved = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = reserved.port;
      await reserved.close();
      final service = serviceFor(port: deadPort);
      DisconnectionType? reason;
      service.onDisconnected = (type) => reason = type;

      await expectLater(service.connect(), throwsA(isA<Exception>()));

      expect(reason, isNull);
    });
  });
}
