enum ConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error
}

extension ConnectionStateExtension on ConnectionState {
  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Desconectado';
      case ConnectionState.connecting:
        return 'Conectando';
      case ConnectionState.connected:
        return 'Conectado';
      case ConnectionState.disconnecting:
        return 'Desconectando';
      case ConnectionState.error:
        return 'Error';
    }
  }
  
  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting => this == ConnectionState.connecting;
  bool get isDisconnected => this == ConnectionState.disconnected;
}

