import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/samsung/samsung_tv_service.dart';

class SamsungTV implements TVInterface {
  final SamsungTVService _service;
  final List<Map<String, dynamic>> services = [];

  SamsungTV({
    String? host,
    String? mac,
    String? deviceName,
    String? modelName,
  }) : _service = SamsungTVService(
          host: host,
          mac: mac,
          deviceName: deviceName,
          modelName: modelName,
        );

  // Delegate properties to service
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

  void addService(service) {
    services.add(service);
  }

  @override
  void setOnDisconnectedCallback(Function(DisconnectionType) callback) {
    _service.setOnDisconnectedCallback(callback);
  }
  
  @override
  void setOnConnectionStateChangedCallback(Function(ConnectionState) callback) {
    // TODO: Implement connection state callback
  }

  @override
  Future<void> connect({String appName = 'DartSamsungSmartTVDriver'}) async {
    return _service.connect(appName: appName);
  }

  @override
  void disconnect() {
    _service.disconnect();
  }

  @override
  Future<void> sendKey(KeyCodes key) async {
    return _service.sendKey(key);
  }

  bool get connectionStatus => _service.connectionStatus;

  @override
  Future<void> ensureConnection() async {
    return _service.ensureConnection();
  }

  static Future<SamsungTV> discover() async {
    final service = await SamsungTVService.discover();
    return SamsungTV(
      host: service.host,
      deviceName: service.deviceName,
      modelName: service.modelName,
    );
  }

  static Future<List<SamsungTV>> discoverAll() async {
    final services = await SamsungTVService.discoverAll();
    return services.map((service) => SamsungTV(
      host: service.host,
      deviceName: service.deviceName,
      modelName: service.modelName,
    )).toList();
  }
}
