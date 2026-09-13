import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/samsung/samsung_tv_service.dart';

class SamsungTV implements TVInterface {
  SamsungTV({
    String? host,
    String? mac,
    String? deviceName,
    String? modelName,
    String? token,
  }) : _service = SamsungTVService(
          host: host,
          mac: mac,
          deviceName: deviceName,
          modelName: modelName,
          token: token,
        );

  SamsungTV.fromService(this._service);

  final SamsungTVService _service;

  @override
  String? get host => _service.host;

  @override
  String? get mac => _service.mac;

  @override
  String? get deviceName => _service.deviceName;

  @override
  String? get modelName => _service.modelName;

  @override
  bool get isConnected => _service.isConnected;

  @override
  ConnectionState get connectionState => _service.isConnected
      ? ConnectionState.connected
      : ConnectionState.disconnected;

  String? get token => _service.token;

  @override
  void setOnDisconnectedCallback(void Function(DisconnectionType) callback) {
    _service.setOnDisconnectedCallback(callback);
  }

  @override
  void setOnConnectionStateChangedCallback(
    void Function(ConnectionState) callback,
  ) {
    // Bloc layer derives this from service state — no callback needed.
  }

  void setOnTokenReceivedCallback(void Function(String token) callback) {
    _service.setOnTokenReceivedCallback(callback);
  }

  @override
  Future<void> connect({String appName = 'DartSamsungSmartTVDriver'}) {
    return _service.connect(appName: appName);
  }

  @override
  void disconnect() => _service.disconnect();

  @override
  Future<void> sendKey(KeyCodes key) => _service.sendKey(key);

  @override
  Future<void> ensureConnection() => _service.ensureConnection();
}
