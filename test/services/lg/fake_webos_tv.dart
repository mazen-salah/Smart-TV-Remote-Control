import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote/services/lg/lg_tv_service.dart';

/// A stand-in for a webOS TV, speaking enough of the protocol to exercise
/// [LgTvService] over a real WebSocket: registration (accept, deny, or
/// reject the signed manifest), `ssap://` requests, and the pointer input
/// socket that carries button presses.
class FakeWebOsTv {
  FakeWebOsTv._(this._server, {this.secure = false, Directory? certificateDir})
    : _certificateDir = certificateDir;

  static Future<FakeWebOsTv> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final tv = FakeWebOsTv._(server);
    unawaited(tv._serve());
    return tv;
  }

  /// Why [startSecure] cannot run here, or null when it can.
  ///
  /// Checked synchronously so a group can be skipped with a reason rather
  /// than failing for a toolchain reason unrelated to the code under test.
  static String? get tlsUnavailableReason {
    try {
      final result = Process.runSync('openssl', ['version']);
      if (result.exitCode != 0) {
        return 'openssl exited ${result.exitCode}';
      }
      return null;
    } on ProcessException catch (e) {
      return 'openssl not usable: ${e.message}';
    }
  }

  /// A TV reachable over TLS with a self-signed certificate, like the real
  /// thing. The certificate is generated per call, so a second instance
  /// presents a different one - which is how a certificate change is
  /// simulated.
  ///
  /// The certificate deliberately carries no subject alternative name: it
  /// cannot validate either way, and every client we test reaches it
  /// through `badCertificateCallback`. That also keeps the arguments to
  /// ones LibreSSL accepts.
  static Future<FakeWebOsTv> startSecure() async {
    final dir = await Directory.systemTemp.createTemp('fake_webos_tv');
    final certPath = '${dir.path}/cert.pem';
    final keyPath = '${dir.path}/key.pem';
    final ProcessResult result;
    try {
      result = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-keyout',
        keyPath,
        '-out',
        certPath,
        '-days',
        '1',
        '-nodes',
        '-subj',
        '/CN=127.0.0.1',
      ]);
    } on ProcessException catch (e) {
      await dir.delete(recursive: true);
      throw StateError('openssl is required for TLS tests: ${e.message}');
    }
    if (result.exitCode != 0) {
      await dir.delete(recursive: true);
      throw StateError('openssl failed: ${result.stderr}');
    }
    final context = SecurityContext()
      ..useCertificateChain(certPath)
      ..usePrivateKey(keyPath);
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    final tv = FakeWebOsTv._(server, secure: true, certificateDir: dir);
    unawaited(tv._serve());
    return tv;
  }

  final HttpServer _server;

  /// Whether the TV is reachable over `wss://` rather than `ws://`.
  final bool secure;

  final Directory? _certificateDir;

  int get port => _server.port;
  String get host => _server.address.address;

  /// Handed to the client as `socketPath`; the same server serves it.
  String get _pointerPath => '${secure ? 'wss' : 'ws'}://$host:$port/pointer';

  /// Registration behaviour for the next connection.
  RegisterBehaviour behaviour = RegisterBehaviour.accept;

  /// Key returned to a client that registers without one.
  String issuedClientKey = 'issued-key-1';

  /// Every `register` payload the TV received, in order.
  final List<Map<String, dynamic>> registerPayloads = [];

  /// Every `ssap://` URI requested on the main socket.
  final List<String> requestedUris = [];

  /// Raw frames received on the pointer socket.
  final List<String> pointerFrames = [];

  final _pointerOpened = Completer<void>();
  Future<void> get pointerSocketOpened => _pointerOpened.future;

  Future<void> _serve() async {
    await for (final request in _server) {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        continue;
      }
      final isPointer = request.uri.path == '/pointer';
      final socket = await WebSocketTransformer.upgrade(request);
      if (isPointer) {
        if (!_pointerOpened.isCompleted) _pointerOpened.complete();
        socket.listen(
          (dynamic frame) => pointerFrames.add(frame as String),
          onError: (Object _) {},
        );
      } else {
        socket.listen(
          (dynamic frame) => _onControlFrame(socket, frame as String),
          onError: (Object _) {},
        );
      }
    }
  }

  void _onControlFrame(WebSocket socket, String frame) {
    final message = jsonDecode(frame) as Map<String, dynamic>;
    final id = message['id'];
    switch (message['type'] as String?) {
      case 'register':
        final payload = Map<String, dynamic>.from(
          message['payload'] as Map<dynamic, dynamic>,
        );
        registerPayloads.add(payload);
        switch (behaviour) {
          case RegisterBehaviour.accept:
            socket.add(
              jsonEncode({
                'id': id,
                'type': 'registered',
                'payload': {
                  'client-key': payload['client-key'] ?? issuedClientKey,
                },
              }),
            );
          case RegisterBehaviour.rejectSignedManifest:
            // Accept the retry that drops the signature, reject the first.
            if (payload case {'manifest': {'signatures': _}}) {
              socket.add(
                jsonEncode({
                  'id': id,
                  'type': 'error',
                  'error': '403 blacklisted certificate detected',
                }),
              );
            } else {
              socket.add(
                jsonEncode({
                  'id': id,
                  'type': 'registered',
                  'payload': {'client-key': issuedClientKey},
                }),
              );
            }
          case RegisterBehaviour.deny:
            socket.add(
              jsonEncode({'id': id, 'type': 'error', 'error': '403 cancelled'}),
            );
          case RegisterBehaviour.silent:
            break;
        }
      case 'request':
        final uri = message['uri'] as String;
        requestedUris.add(uri);
        if (uri.endsWith('getPointerInputSocket')) {
          socket.add(
            jsonEncode({
              'id': id,
              'type': 'response',
              'payload': {'socketPath': _pointerPath},
            }),
          );
        } else {
          socket.add(
            jsonEncode({
              'id': id,
              'type': 'response',
              'payload': {'returnValue': true},
            }),
          );
        }
      default:
        break;
    }
  }

  Future<void> close() async {
    await _server.close(force: true);
    await _certificateDir?.delete(recursive: true);
  }
}

enum RegisterBehaviour {
  /// Reply `registered`, echoing a supplied key or issuing a new one.
  accept,

  /// Reject a payload carrying `signatures`, accept the unsigned retry.
  rejectSignedManifest,

  /// The user pressed Deny on the TV.
  deny,

  /// Never answer the register message.
  silent,
}
