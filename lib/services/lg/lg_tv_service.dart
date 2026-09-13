import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/lg/lg_pairing.dart';
import 'package:web_socket_channel/io.dart';

/// How long the user gets to accept the on-screen pairing prompt.
const Duration kLgPairingTimeout = Duration(seconds: 60);
const Duration kLgSocketOpenTimeout = Duration(seconds: 4);
const Duration kLgRequestTimeout = Duration(seconds: 5);
const Duration kLgPingInterval = Duration(seconds: 10);

/// LG webOS remote-control client.
///
/// Transport: TVs updated since January 2023 (webOS 23 and newer firmware on
/// older models) only accept `wss://<host>:3001` with a self-signed
/// certificate; sets from before 2018 only offer `ws://<host>:3000`. We try
/// the secure port first and fall back, then remember which one worked.
///
/// Certificate: the TV's certificate is self-signed, so it is pinned on
/// first use (trust-on-first-use): the SHA-256 of the certificate seen when
/// the user approved pairing is handed to [onCertificatePinned], and later
/// connections reject any other certificate. The saved `client-key` is only
/// ever sent over a pinned TLS connection; on the plaintext fallback the TV
/// is asked to pair again instead.
///
/// Pairing: send a `register` message carrying LG's signed sample manifest.
/// With a saved `client-key` the TV answers `registered` at once; without one
/// it shows an on-screen prompt and returns a fresh key that must be
/// persisted. If the TV rejects the signed manifest we retry once unsigned,
/// the same way lgtv2 does.
///
/// Keys: navigation, colour and digit keys go through the pointer input
/// socket (`type:button\nname:UP\n\n`), obtained from
/// `ssap://com.webos.service.networkinput/getPointerInputSocket`. Everything
/// else is an `ssap://` request on the main socket.
class LgTvService {
  LgTvService({
    required this.host,
    String? clientKey,
    String? pinnedCertificateSha256,
    bool preferSecure = true,
  })  : _clientKey = clientKey,
        _pinnedCert = pinnedCertificateSha256,
        _secure = preferSecure;

  final String host;

  String? _clientKey;
  String? get clientKey => _clientKey;

  bool _secure;

  /// SHA-256 (lowercase hex) of the certificate approved on first use.
  String? _pinnedCert;
  String? get pinnedCertificateSha256 => _pinnedCert;
  String? _seenCert;
  bool _certificateRejected = false;

  /// Whether the last successful connection used `wss://:3001`.
  bool get usesSecureTransport => _secure;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  IOWebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  IOWebSocketChannel? _pointer;
  Completer<IOWebSocketChannel>? _pointerOpening;

  int _nextId = 1;
  int _generation = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  Completer<void>? _registration;
  bool _triedUnsigned = false;

  void Function(DisconnectionType)? onDisconnected;
  void Function(String key)? onClientKeyReceived;

  /// Called once the TV has registered us over TLS, with the certificate
  /// fingerprint to remember for that TV.
  void Function(String sha256)? onCertificatePinned;

  Uri get _secureUri => Uri(scheme: 'wss', host: host, port: 3001);
  Uri get _plainUri => Uri(scheme: 'ws', host: host, port: 3000);

  HttpClient _pinningClient() => HttpClient()
    ..badCertificateCallback = (cert, host, port) {
      final fingerprint = sha256.convert(cert.der).toString();
      _seenCert = fingerprint;
      final pinned = _pinnedCert;
      if (pinned == null) return true; // first use: pin after pairing
      if (fingerprint == pinned) return true;
      _certificateRejected = true;
      log('LG: certificate for $host changed (expected $pinned, got $fingerprint)');
      return false;
    };

  Future<void> connect() async {
    if (_isConnected) return;

    final candidates =
        _secure ? [_secureUri, _plainUri] : [_plainUri, _secureUri];
    Object? lastError;
    for (final uri in candidates) {
      _certificateRejected = false;
      try {
        await _connectTo(uri);
        _secure = uri.scheme == 'wss';
        return;
      } on _SocketOpenFailure catch (e) {
        _teardown();
        if (_certificateRejected) {
          // Never fall back to plaintext when TLS failed because the TV's
          // certificate is not the one we pinned.
          throw Exception(
            'LG certificate changed; forget this TV and pair again',
          );
        }
        log('LG: ${uri.scheme}://${uri.host}:${uri.port} unreachable: $e');
        lastError = e;
      } catch (e) {
        // The socket opened but registration failed or timed out. Trying
        // the other port would not help and would drop the pairing prompt.
        _teardown();
        throw Exception('LG connect failed: $e');
      }
    }
    throw Exception('LG connect failed: $lastError');
  }

  Future<void> _connectTo(Uri uri) async {
    final secure = uri.scheme == 'wss';
    final IOWebSocketChannel channel;
    try {
      channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: kLgPingInterval,
        connectTimeout: kLgSocketOpenTimeout,
        customClient: secure ? _pinningClient() : null,
      );
      await channel.ready.timeout(kLgSocketOpenTimeout);
    } catch (e) {
      throw _SocketOpenFailure(e);
    }

    final registration = Completer<void>();
    _registration = registration;
    _triedUnsigned = false;
    _ws = channel;
    _wsSub = channel.stream.listen(
      _onMessage,
      onError: (Object error) {
        if (!registration.isCompleted) {
          registration.completeError(Exception('LG WebSocket failed: $error'));
        }
        _handleDisconnection(_classify(error));
      },
      onDone: () {
        if (!registration.isCompleted) {
          registration.completeError(
            Exception('LG WebSocket closed before register'),
          );
        }
        _handleDisconnection(DisconnectionType.tvPowerOff);
      },
    );

    // The saved key is only sent over TLS; on plaintext the TV re-prompts.
    _sendKeyInRegister = secure;
    channel.sink.add(jsonEncode(_registerPayload(signed: true)));
    await registration.future.timeout(
      kLgPairingTimeout,
      onTimeout: () => throw TimeoutException('LG pairing not accepted'),
    );
    if (secure) {
      final seen = _seenCert;
      if (_pinnedCert == null && seen != null) {
        _pinnedCert = seen;
        onCertificatePinned?.call(seen);
      }
    }
  }

  bool _sendKeyInRegister = true;

  void _onMessage(dynamic raw) {
    final data = _decode(raw);
    if (data == null) return;
    final type = data['type'] as String?;
    final id = data['id']?.toString();
    final payload = data['payload'];
    final payloadMap = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};

    switch (type) {
      case 'registered':
        final key = payloadMap['client-key'] as String?;
        if (key != null && key != _clientKey && _sendKeyInRegister) {
          _clientKey = key;
          onClientKeyReceived?.call(key);
        }
        _isConnected = true;
        final reg = _registration;
        if (reg != null && !reg.isCompleted) reg.complete();
      case 'response':
        _pending.remove(id)?.complete(payloadMap);
      case 'error':
        final error = payloadMap['error'] ?? data['error'];
        final reg = _registration;
        if (reg != null && !reg.isCompleted) {
          if (!_triedUnsigned) {
            // Some firmware rejects the signed sample manifest; retry once
            // without the signature, as lgtv2 does.
            _triedUnsigned = true;
            log('LG: signed register rejected ($error), retrying unsigned');
            _ws?.sink.add(jsonEncode(_registerPayload(signed: false)));
          } else {
            reg.completeError(Exception('LG register failed: $error'));
          }
          return;
        }
        _pending.remove(id)?.completeError(Exception('LG error: $error'));
      default:
        break;
    }
  }

  String _send(String uri, Map<String, dynamic>? payload) {
    final ws = _ws;
    if (!_isConnected || ws == null || ws.closeCode != null) {
      throw StateError('LG TV not connected');
    }
    final id = '${_nextId++}';
    ws.sink.add(
      jsonEncode(<String, dynamic>{
        'id': id,
        'type': 'request',
        'uri': uri,
        if (payload != null) 'payload': payload,
      }),
    );
    return id;
  }

  /// Sends an `ssap://` request and resolves with the response payload.
  Future<Map<String, dynamic>> request(
    String uri, {
    Map<String, dynamic>? payload,
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    final id = _send(uri, payload);
    _pending[id] = completer;
    return await completer.future.timeout(
      kLgRequestTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('LG request $uri timed out');
      },
    );
  }

  /// Sends a command without waiting for the TV's reply. Throws only when
  /// there is no connection to send on.
  Future<void> sendUri(String uri, {Map<String, dynamic>? payload}) async {
    _send(uri, payload);
  }

  /// Presses a remote button through the pointer input socket.
  Future<void> sendButton(String name) async {
    final socket = await _pointerSocket();
    socket.sink.add('type:button\nname:$name\n\n');
  }

  Future<IOWebSocketChannel> _pointerSocket() async {
    final existing = _pointer;
    if (existing != null && existing.closeCode == null) return existing;
    final opening = _pointerOpening;
    if (opening != null) return await opening.future;

    final completer = Completer<IOWebSocketChannel>();
    final generation = _generation;
    _pointerOpening = completer;
    try {
      final response = await request(
        'ssap://com.webos.service.networkinput/getPointerInputSocket',
      );
      final path = response['socketPath'] as String?;
      if (path == null) {
        throw StateError('LG did not return a pointer socket path');
      }
      final uri = Uri.parse(path);
      final channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: kLgSocketOpenTimeout,
        customClient: uri.scheme == 'wss' ? _pinningClient() : null,
      );
      await channel.ready;
      if (generation != _generation) {
        // Disconnected while the socket was opening; don't keep it.
        unawaited(channel.sink.close());
        throw StateError('LG connection closed');
      }
      channel.stream.listen(
        (_) {},
        onError: (Object e) => _dropPointer(channel),
        onDone: () => _dropPointer(channel),
      );
      _pointer = channel;
      completer.complete(channel);
    } catch (e) {
      completer.completeError(e);
    } finally {
      if (identical(_pointerOpening, completer)) _pointerOpening = null;
    }
    return await completer.future;
  }

  void _dropPointer(IOWebSocketChannel channel) {
    if (identical(_pointer, channel)) _pointer = null;
  }

  Future<void> launchApp(String appId) =>
      sendUri('ssap://system.launcher/launch', payload: {'id': appId});

  Future<void> setVolume(int volume) =>
      sendUri('ssap://audio/setVolume', payload: {'volume': volume});

  Future<void> volumeUp() => sendUri('ssap://audio/volumeUp');
  Future<void> volumeDown() => sendUri('ssap://audio/volumeDown');
  Future<void> setMute({required bool mute}) =>
      sendUri('ssap://audio/setMute', payload: {'mute': mute});

  Future<void> channelUp() => sendUri('ssap://tv/channelUp');
  Future<void> channelDown() => sendUri('ssap://tv/channelDown');

  /// `play`, `pause`, `stop`, `rewind` or `fastForward`.
  Future<void> media(String command) =>
      sendUri('ssap://media.controls/$command');

  Future<void> power() => sendUri('ssap://system/turnOff');

  void disconnect() {
    if (!_isConnected && _ws == null) return;
    _teardown();
  }

  void _teardown() {
    _generation++;
    _pointerOpening = null;
    _isConnected = false;
    unawaited(_wsSub?.cancel());
    _wsSub = null;
    unawaited(_ws?.sink.close());
    _ws = null;
    unawaited(_pointer?.sink.close());
    _pointer = null;
    for (final pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(StateError('LG connection closed'));
      }
    }
    _pending.clear();
  }

  void _handleDisconnection(DisconnectionType type) {
    if (!_isConnected && _ws == null) return;
    _teardown();
    onDisconnected?.call(type);
  }

  Map<String, dynamic>? _decode(dynamic raw) {
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      log('LG: could not parse $raw ($e)');
      return null;
    }
  }

  DisconnectionType _classify(Object error) {
    final m = error.toString().toLowerCase();
    if (m.contains('connection refused') || m.contains('errno = 111')) {
      return DisconnectionType.tvPowerOff;
    }
    if (m.contains('unauthorized')) {
      return DisconnectionType.authenticationFailed;
    }
    return DisconnectionType.unknown;
  }

  Map<String, dynamic> _registerPayload({required bool signed}) {
    final pairing = jsonDecode(kLgPairingJson) as Map<String, dynamic>;
    final manifest = pairing['manifest'] as Map<String, dynamic>;
    if (!signed) {
      manifest
        ..remove('signed')
        ..remove('signatures')
        ..['appVersion'] = '1.0';
      (manifest['permissions'] as List<dynamic>)
          .addAll(['CONTROL_INPUT_TEXT', 'CONTROL_MOUSE_AND_KEYBOARD']);
    }
    return <String, dynamic>{
      'id': 'register_0',
      'type': 'register',
      'payload': <String, dynamic>{
        ...pairing,
        if (_sendKeyInRegister && _clientKey != null) 'client-key': _clientKey,
      },
    };
  }
}

/// The TCP/TLS/WebSocket handshake itself failed, as opposed to the TV
/// refusing or timing out the registration afterwards.
class _SocketOpenFailure implements Exception {
  _SocketOpenFailure(this.cause);
  final Object cause;

  @override
  String toString() => cause.toString();
}
