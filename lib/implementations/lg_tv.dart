import 'dart:developer';

import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/lg/lg_buttons.dart';
import 'package:remote/services/lg/lg_tv_service.dart';

/// LG webOS implementation of [TVInterface]. Key mapping lives in
/// `lg_buttons.dart`; keys with no webOS equivalent are logged and ignored.
class LGTV implements TVInterface {
  LGTV({
    required String host,
    String? mac,
    String? deviceName,
    String? modelName,
    String? clientKey,
  }) : _service = LgTvService(host: host, clientKey: clientKey),
       _host = host,
       _mac = mac,
       _deviceName = deviceName,
       _modelName = modelName;

  final LgTvService _service;
  final String _host;
  final String? _mac;
  final String? _deviceName;
  final String? _modelName;

  @override
  String? get host => _host;
  @override
  String? get mac => _mac;
  @override
  String? get deviceName => _deviceName;
  @override
  String? get modelName => _modelName;

  @override
  bool get isConnected => _service.isConnected;

  @override
  ConnectionState get connectionState => _service.isConnected
      ? ConnectionState.connected
      : ConnectionState.disconnected;

  String? get clientKey => _service.clientKey;

  @override
  void setOnDisconnectedCallback(void Function(DisconnectionType) callback) {
    _service.onDisconnected = callback;
  }

  @override
  void setOnConnectionStateChangedCallback(
    void Function(ConnectionState) callback,
  ) {
    // Bloc layer derives state — no callback required.
  }

  void setOnClientKeyReceivedCallback(void Function(String key) callback) {
    _service.onClientKeyReceived = callback;
  }

  @override
  Future<void> connect({String appName = 'Smart TV Remote'}) =>
      _service.connect();

  @override
  void disconnect() => _service.disconnect();

  @override
  Future<void> ensureConnection() async {
    if (!_service.isConnected) await _service.connect();
  }

  @override
  Future<void> sendKey(KeyCodes key) async {
    await ensureConnection();
    if (key == KeyCodes.KEY_POWER) {
      await _service.power();
      return;
    }
    final media = lgMediaCommandFor(key);
    if (media != null) {
      await _service.media(media);
      return;
    }
    final button = lgButtonFor(key);
    if (button != null) {
      await _service.sendButton(button);
      return;
    }
    log('LG: no webOS mapping for ${key.name}, ignored');
  }

  Future<void> launchApp(String appId) => _service.launchApp(appId);
}
