import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote/services/lg/lg_tv_service.dart';

import 'fake_webos_tv.dart';

/// Exercises the webOS client against a local stand-in TV over a real
/// WebSocket. Everything runs on the plaintext port: `securePort` points at
/// a closed port so each test also covers the fall back from `wss://:3001`.
void main() {
  late FakeWebOsTv tv;
  late int deadPort;

  setUp(() async {
    tv = await FakeWebOsTv.start();
    // Reserve an ephemeral port and release it: nothing listens there, so
    // the TLS attempt fails fast and the fallback path is exercised.
    final reserved = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    deadPort = reserved.port;
    await reserved.close();
  });

  tearDown(() => tv.close());

  LgTvService serviceFor({String? clientKey, String? pinnedCertificate}) =>
      LgTvService(
        host: tv.host,
        clientKey: clientKey,
        pinnedCertificateSha256: pinnedCertificate,
        securePort: deadPort,
        plainPort: tv.port,
      );

  group('connect', () {
    test('falls back to the plaintext port when TLS is unreachable', () async {
      final service = serviceFor();
      await service.connect();
      expect(service.isConnected, isTrue);
      expect(tv.registerPayloads, hasLength(1));
      service.disconnect();
    });

    test('discards a key issued over plaintext', () async {
      final service = serviceFor();
      String? received;
      service.onClientKeyReceived = (key) => received = key;
      await service.connect();
      // Storing it would mean sending it back over plaintext next time.
      expect(received, isNull);
      expect(service.clientKey, isNull);
      service.disconnect();
    });

    test('never sends a saved key to a TV it has not pinned', () async {
      final service = serviceFor(clientKey: 'saved-key');
      await service.connect();
      // Plaintext transport and no pin: the key must stay on the device.
      expect(tv.registerPayloads.single.containsKey('client-key'), isFalse);
      service.disconnect();
    });

    test('retries unsigned when the TV rejects the signed manifest', () async {
      tv.behaviour = RegisterBehaviour.rejectSignedManifest;
      final service = serviceFor();
      await service.connect();
      expect(service.isConnected, isTrue);
      expect(tv.registerPayloads, hasLength(2));
      final manifest =
          tv.registerPayloads.last['manifest']! as Map<String, dynamic>;
      expect(manifest.containsKey('signatures'), isFalse);
      expect(manifest.containsKey('signed'), isFalse);
      service.disconnect();
    });

    test('does not re-prompt when the user denies pairing', () async {
      tv.behaviour = RegisterBehaviour.deny;
      final service = serviceFor();
      await expectLater(service.connect(), throwsA(isA<Exception>()));
      expect(tv.registerPayloads, hasLength(1));
      expect(service.isConnected, isFalse);
    });

    test('reports a TV that never answers the register message', () async {
      tv.behaviour = RegisterBehaviour.silent;
      final service = LgTvService(
        host: tv.host,
        securePort: deadPort,
        plainPort: tv.port,
      );
      // Shorten the wait by racing the pairing window.
      await expectLater(
        service.connect().timeout(const Duration(seconds: 2)),
        throwsA(anything),
      );
      expect(service.isConnected, isFalse);
    });
  });

  group('over TLS', () {
    late FakeWebOsTv secureTv;

    setUp(() async => secureTv = await FakeWebOsTv.startSecure());
    tearDown(() => secureTv.close());

    LgTvService secureServiceFor({
      String? clientKey,
      String? pinnedCertificate,
    }) => LgTvService(
      host: secureTv.host,
      clientKey: clientKey,
      pinnedCertificateSha256: pinnedCertificate,
      securePort: secureTv.port,
      // If the client ever fell back, this plaintext TV would see it.
      plainPort: tv.port,
    );

    test('pins the certificate and keeps the key issued by the TV', () async {
      final service = secureServiceFor();
      String? pinned;
      String? key;
      service
        ..onCertificatePinned = (sha) {
          pinned = sha;
        }
        ..onClientKeyReceived = (k) {
          key = k;
        };

      await service.connect();

      expect(service.isConnected, isTrue);
      expect(pinned, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(key, secureTv.issuedClientKey);
      service.disconnect();
    });

    test('sends the saved key once the certificate is pinned', () async {
      // First connection pins; a second one may use the saved key.
      final first = secureServiceFor();
      String? pinned;
      first.onCertificatePinned = (sha) {
        pinned = sha;
      };
      await first.connect();
      first.disconnect();

      final second = secureServiceFor(
        clientKey: 'saved-key',
        pinnedCertificate: pinned,
      );
      await second.connect();

      expect(secureTv.registerPayloads.last['client-key'], 'saved-key');
      second.disconnect();
    });

    test(
      'rejects a changed certificate without falling back to plaintext',
      () async {
        final service = secureServiceFor(
          clientKey: 'saved-key',
          pinnedCertificate: 'f' * 64,
        );

        await expectLater(service.connect(), throwsA(isA<Exception>()));

        expect(service.isConnected, isFalse);
        expect(secureTv.registerPayloads, isEmpty);
        // The saved key must not have leaked to the plaintext port either.
        expect(tv.registerPayloads, isEmpty);
      },
    );
  }, skip: FakeWebOsTv.tlsUnavailableReason);

  group('commands', () {
    test('sends ssap requests on the main socket', () async {
      final service = serviceFor();
      await service.connect();
      await service.power();
      await service.media('play');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(tv.requestedUris, contains('ssap://system/turnOff'));
      expect(tv.requestedUris, contains('ssap://media.controls/play'));
      service.disconnect();
    });

    test('presses buttons on the pointer input socket', () async {
      final service = serviceFor();
      await service.connect();
      await service.sendButton('UP');
      await tv.pointerSocketOpened;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        tv.requestedUris,
        contains('ssap://com.webos.service.networkinput/getPointerInputSocket'),
      );
      expect(tv.pointerFrames, ['type:button\nname:UP\n\n']);
      service.disconnect();
    });

    test('reuses one pointer socket for repeated presses', () async {
      final service = serviceFor();
      await service.connect();
      await service.sendButton('LEFT');
      await service.sendButton('RIGHT');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final handshakes = tv.requestedUris
          .where((u) => u.endsWith('getPointerInputSocket'))
          .length;
      expect(handshakes, 1);
      expect(tv.pointerFrames, hasLength(2));
      service.disconnect();
    });

    test('refuses to send once disconnected', () async {
      final service = serviceFor();
      await service.connect();
      service.disconnect();
      expect(service.power, throwsA(isA<StateError>()));
    });
  });
}
