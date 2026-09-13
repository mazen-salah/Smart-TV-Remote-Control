import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/lg/lg_pairing.dart';
import 'package:web_socket_channel/io.dart';

const Duration kLgConnectTimeout = Duration(seconds: 12);
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
    bool preferSecure = true,
  })  : _clientKey = clientKey,
        _secure = preferSecure;

  final String host;

  String? _clientKey;
  String? get clientKey => _clientKey;

  bool _secure;

  /// Whether the last successful connection used `wss://:3001`.
  bool get usesSecureTransport => _secure;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  IOWebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  IOWebSocketChannel? _pointer;
  Completer<IOWebSocketChannel>? _pointerOpening;

  int _nextId = 1;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  Completer<void>? _registration;
  bool _triedUnsigned = false;

  void Function(DisconnectionType)? onDisconnected;
  void Function(String key)? onClientKeyReceived;

  Uri get _secureUri => Uri(scheme: 'wss', host: host, port: 3001);
  Uri get _plainUri => Uri(scheme: 'ws', host: host, port: 3000);

  static HttpClient _insecureClient() =>
      HttpClient()..badCertificateCallback = (cert, host, port) => true;

  Future<void> connect() async {
    if (_isConnected) return;

    final candidates =
        _secure ? [_secureUri, _plainUri] : [_plainUri, _secureUri];
    Object? lastError;
    for (final uri in candidates) {
      try {
        await _connectTo(uri).timeout(kLgConnectTimeout);
        _secure = uri.scheme == 'wss';
        return;
      } catch (e) {
        log('LG: ${uri.scheme}://${uri.host}:${uri.port} failed: $e');
        lastError = e;
        _teardown();
      }
    }
    throw Exception('LG connect failed: $lastError');
  }

  Future<void> _connectTo(Uri uri) async {
    final channel = IOWebSocketChannel.connect(
      uri,
      pingInterval: kLgPingInterval,
      connectTimeout: kLgSocketOpenTimeout,
      customClient: uri.scheme == 'wss' ? _insecureClient() : null,
    );
    await channel.ready;

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

    channel.sink.add(jsonEncode(_registerPayload(signed: true)));
    await registration.future;
  }

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
        if (key != null && key != _clientKey) {
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

  /// Sends an `ssap://` request and resolves with the response payload.
  Future<Map<String, dynamic>> request(
    String uri, {
    Map<String, dynamic>? payload,
  }) async {
    final ws = _ws;
    if (!_isConnected || ws == null || ws.closeCode != null) {
      throw StateError('LG TV not connected');
    }
    final id = '${_nextId++}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    ws.sink.add(
      jsonEncode(<String, dynamic>{
        'id': id,
        'type': 'request',
        'uri': uri,
        if (payload != null) 'payload': payload,
      }),
    );
    return await completer.future.timeout(
      kLgRequestTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('LG request $uri timed out');
      },
    );
  }

  /// Fire-and-forget variant of [request]; failures are only logged.
  Future<void> sendUri(String uri, {Map<String, dynamic>? payload}) async {
    try {
      await request(uri, payload: payload);
    } on TimeoutException {
      // The TV acts on most commands without replying; not an error.
    } catch (e) {
      log('LG: $uri failed: $e');
      rethrow;
    }
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
        customClient: uri.scheme == 'wss' ? _insecureClient() : null,
      );
      await channel.ready;
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
      _pointerOpening = null;
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
        if (_clientKey != null) 'client-key': _clientKey,
      },
    };
  }
}
