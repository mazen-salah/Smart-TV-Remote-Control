import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';

/// Interfaz base para todos los modelos de TV
abstract class TVInterface {
  /// Propiedades básicas del dispositivo
  String? get host;
  String? get mac;
  String? get deviceName;
  String? get modelName;
  
  /// Estado de conexión
  bool get isConnected;
  ConnectionState get connectionState;
  
  /// Métodos de conexión
  Future<void> connect({String appName});
  void disconnect();
  Future<void> ensureConnection();
  
  /// Métodos de control
  Future<void> sendKey(KeyCodes key);
  
  /// Callbacks
  void setOnDisconnectedCallback(Function(DisconnectionType) callback);
  void setOnConnectionStateChangedCallback(Function(ConnectionState) callback);
  
  /// Métodos de discovery (estáticos)
  static Future<TVInterface> discover() {
    throw UnimplementedError('Discovery must be implemented by concrete classes');
  }
  
  static Future<List<TVInterface>> discoverAll() {
    throw UnimplementedError('Discovery must be implemented by concrete classes');
  }
}

