import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/sony/sony_tv_service.dart';

/// Sony BRAVIA implementation of [TVInterface]. Button codes live in
/// `sony_ircc.dart`; keys with no IRCC equivalent are logged and ignored.
class SonyTV implements TVInterface {
  SonyTV({
    required String host,
    String? mac,
    String? deviceName,
    String? modelName,
    String? preSharedKey,
    int? port,
    SonyTvService? service,
  }) : _service =
           service ??
           SonyTvService(
             host: host,
             port: port ?? 80,
             preSharedKey: preSharedKey,
           ),
       _host = host,
       _mac = mac,
       _deviceName = deviceName,
       _modelName = modelName;

  final SonyTvService _service;
  final String _host;
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
}
