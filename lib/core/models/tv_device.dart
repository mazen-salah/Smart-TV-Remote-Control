import 'package:remote/core/models/connection_state.dart';

/// Modelo de dominio para un dispositivo TV
class TVDevice {
  final String? host;
  final String? mac;
  final String? deviceName;
  final String? modelName;
  final String? manufacturer;
  final String? serialNumber;
  final Map<String, dynamic> additionalInfo;
  
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  TVDevice({
    this.host,
    this.mac,
    this.deviceName,
    this.modelName,
    this.manufacturer,
    this.serialNumber,
    Map<String, dynamic>? additionalInfo,
  }) : additionalInfo = additionalInfo ?? {};
  
  ConnectionState get connectionState => _connectionState;
  
  void updateConnectionState(ConnectionState state) {
    _connectionState = state;
  }
  
  bool get isConnected => _connectionState.isConnected;
  bool get isConnecting => _connectionState.isConnecting;
  bool get isDisconnected => _connectionState.isDisconnected;
  
  String get displayName => deviceName ?? modelName ?? 'TV Desconocido';
  
  @override
  String toString() {
    return 'TVDevice(host: $host, name: $displayName, state: ${_connectionState.displayName})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TVDevice && 
           other.host == host && 
           other.mac == mac;
  }
  
  @override
  int get hashCode => host.hashCode ^ mac.hashCode;
}

