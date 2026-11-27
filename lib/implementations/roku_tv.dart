import 'dart:developer';

import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/roku/roku_tv_service.dart';

/// Roku implementation of [TVInterface]. Key mapping lives in
/// `roku_buttons.dart`; keys with no ECP equivalent are logged and ignored.
class RokuTV implements TVInterface {
  RokuTV({
    required String host,
    String? mac,
    String? deviceName,
    String? modelName,
    int? port,
    RokuTvService? service,
  }) : _service =
           service ??
           RokuTvService(host: host, port: port ?? RokuTvService.defaultPort),
       _host = host,
       _mac = mac,
       _deviceName = deviceName,
       _modelName = modelName;

  final RokuTvService _service;
  final String? _host;
  final String? _mac;
  final String? _deviceName;
  final String? _modelName;

  @override
  String? get host => _host;

  @override
  String? get mac => _service.mac ?? _mac;

  @override
  String? get deviceName => _service.deviceName ?? _deviceName;

  @override
  String? get modelName => _service.modelName ?? _modelName;

  String? get serialNumber => _service.serialNumber;

  @override
  bool get isConnected => _service.isConnected;

  @override
  ConnectionState get connectionState => _service.isConnected
      ? ConnectionState.connected
      : ConnectionState.disconnected;

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

  @override
  Future<void> connect({String appName = 'Smart TV Remote'}) =>
      _service.connect();

  @override
  void disconnect() => _service.disconnect();

  @override
  Future<void> ensureConnection() => _service.ensureConnection();

  @override
  Future<void> sendKey(KeyCodes key) => _service.sendKey(key);

  Future<void> launchApp(String appId) {
    log('Roku: launching $appId');
    return _service.launchApp(appId);
  }
}
