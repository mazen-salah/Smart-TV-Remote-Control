import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/lg/lg_tv_service.dart';

/// Maps Samsung-style [KeyCodes] (the shared interface) to LG WebOS commands.
/// Not every key has a one-to-one mapping; unmapped keys are no-ops.
class LGTV implements TVInterface {
  LGTV({
    required String host,
    String? mac,
    String? deviceName,
    String? modelName,
    String? clientKey,
  })  : _service = LgTvService(host: host, clientKey: clientKey),
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
    switch (key) {
      case KeyCodes.KEY_POWER:
        await _service.power();
      case KeyCodes.KEY_VOLUP:
        await _service.volumeUp();
      case KeyCodes.KEY_VOLDOWN:
        await _service.volumeDown();
      case KeyCodes.KEY_MUTE:
        await _service.mute(true);
      case KeyCodes.KEY_CHUP:
        await _service.channelUp();
      case KeyCodes.KEY_CHDOWN:
        await _service.channelDown();
      case KeyCodes.KEY_HOME:
        await _service.sendUri(
          'ssap://system.launcher/launch',
          payload: {'id': 'com.webos.app.home'},
        );
      case _:
        // Unsupported key for LG path right now; ignored silently.
        break;
    }
  }

  Future<void> launchApp(String appId) => _service.launchApp(appId);
}
