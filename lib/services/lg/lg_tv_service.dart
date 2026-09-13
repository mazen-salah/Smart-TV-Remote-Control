import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:remote/core/models/disconnection_type.dart';
import 'package:web_socket_channel/io.dart';

const Duration kLgConnectTimeout = Duration(seconds: 12);
const Duration kLgPingInterval = Duration(seconds: 10);

/// LG WebOS over WebSocket (port 3000 plaintext, 3001 TLS).
///
/// Pairing flow:
///   1. Open ws://host:3000
///   2. Send `register` payload. If we already have a `client-key`, include it
///      — TV replies `registered` immediately.
///      If not, TV shows "Allow" prompt on screen, then replies `registered`
///      with a fresh client-key we must persist for next time.
///   3. Issue commands via `{ id, type: 'request', uri: 'ssap://...' }`.
class LgTvService {
  LgTvService({required this.host, String? clientKey})
    : api = 'ws://$host:3000',
      _clientKey = clientKey;

  final String host;
  final String api;

  String? _clientKey;
  String? get clientKey => _clientKey;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  IOWebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  int _nextId = 1;

  void Function(DisconnectionType)? onDisconnected;
  void Function(String key)? onClientKeyReceived;

  Future<void> connect() async {
    if (_isConnected) return;

    final completer = Completer<void>();
    try {
      _ws = IOWebSocketChannel.connect(
        Uri.parse(api),
        pingInterval: kLgPingInterval,
      );

      _wsSub = _ws!.stream.listen(
        (dynamic message) {
          final data = _decode(message);
          if (data == null) return;
          final type = data['type'] as String?;
          final payload = data['payload'];

          if (type == 'registered' && payload is Map) {
            final key = payload['client-key'] as String?;
            if (key != null && key != _clientKey) {
              _clientKey = key;
              onClientKeyReceived?.call(key);
            }
            _isConnected = true;
            if (!completer.isCompleted) completer.complete();
          } else if (type == 'response') {
            // Command response — no global state to update.
          } else if (type == 'error') {
            final error = payload is Map ? payload['error'] : data['error'];
            if (!completer.isCompleted) {
              completer.completeError(Exception('LG error: $error'));
            }
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('LG WebSocket failed: $error'));
          }
          _handleDisconnection(_classify(error));
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('LG WebSocket closed before register'),
            );
          }
          _handleDisconnection(DisconnectionType.tvPowerOff);
        },
      );

      _ws!.sink.add(jsonEncode(_buildRegisterPayload()));

      Timer(kLgConnectTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(Exception('LG connection timeout'));
        }
      });
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('LG connect failed: $e'));
      }
    }

    return await completer.future;
  }

  Future<void> sendUri(String uri, {Map<String, dynamic>? payload}) async {
    final ws = _ws;
    if (!_isConnected || ws == null || ws.closeCode != null) {
      throw StateError('LG TV not connected');
    }
    final message = <String, dynamic>{
      'id': '${_nextId++}',
      'type': 'request',
      'uri': uri,
      'payload': ?payload,
    };
    ws.sink.add(jsonEncode(message));
  }

  Future<void> launchApp(String appId) =>
      sendUri('ssap://system.launcher/launch', payload: {'id': appId});

  Future<void> setVolume(int volume) =>
      sendUri('ssap://audio/setVolume', payload: {'volume': volume});

  Future<void> volumeUp() => sendUri('ssap://audio/volumeUp');
  Future<void> volumeDown() => sendUri('ssap://audio/volumeDown');
  Future<void> mute(bool mute) =>
      sendUri('ssap://audio/setMute', payload: {'mute': mute});

  Future<void> channelUp() => sendUri('ssap://tv/channelUp');
  Future<void> channelDown() => sendUri('ssap://tv/channelDown');

  Future<void> power() => sendUri('ssap://system/turnOff');

  void disconnect() {
    if (!_isConnected && _ws == null) return;
    _isConnected = false;
    unawaited(_wsSub?.cancel());
    _wsSub = null;
    unawaited(_ws?.sink.close());
    _ws = null;
  }

  void _handleDisconnection(DisconnectionType type) {
    if (!_isConnected && _ws == null) return;
    _isConnected = false;
    unawaited(_wsSub?.cancel());
    _wsSub = null;
    unawaited(_ws?.sink.close());
    _ws = null;
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

  Map<String, dynamic> _buildRegisterPayload() {
    return <String, dynamic>{
      'id': 'register_0',
      'type': 'register',
      'payload': <String, dynamic>{
        'forcePairing': false,
        'pairingType': 'PROMPT',
        if (_clientKey != null) 'client-key': _clientKey,
        'manifest': <String, dynamic>{
          'manifestVersion': 1,
          'appVersion': '1.1',
          'signed': <String, dynamic>{
            'created': '20140509',
            'appId': 'com.lge.test',
            'vendorId': 'com.lge',
            'localizedAppNames': <String, dynamic>{'': 'Smart TV Remote'},
            'permissions': const <String>[
              'CONTROL_INPUT_TEXT',
              'CONTROL_MOUSE_AND_KEYBOARD',
              'READ_INSTALLED_APPS',
              'READ_LGE_SDX',
              'READ_NOTIFICATIONS',
              'SEARCH',
              'WRITE_SETTINGS',
              'WRITE_NOTIFICATION_ALERT',
              'CONTROL_POWER',
              'READ_CURRENT_CHANNEL',
              'READ_RUNNING_APPS',
              'READ_UPDATE_INFO',
              'UPDATE_FROM_REMOTE_APP',
              'READ_LGE_TV_INPUT_EVENTS',
              'READ_TV_CURRENT_TIME',
            ],
          },
          'permissions': const <String>[
            'LAUNCH',
            'LAUNCH_WEBAPP',
            'APP_TO_APP',
            'CONTROL_AUDIO',
            'CONTROL_INPUT_MEDIA_PLAYBACK',
            'CONTROL_POWER',
            'READ_INSTALLED_APPS',
            'CONTROL_DISPLAY',
            'CONTROL_INPUT_JOYSTICK',
            'CONTROL_INPUT_MEDIA_RECORDING',
            'CONTROL_INPUT_TV',
            'READ_INPUT_DEVICE_LIST',
            'READ_NETWORK_STATE',
            'READ_TV_CHANNEL_LIST',
            'WRITE_NOTIFICATION_TOAST',
          ],
        },
      },
    };
  }
}
