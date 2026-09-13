enum ConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

extension ConnectionStateExtension on ConnectionState {
  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.disconnecting:
        return 'Disconnecting';
      case ConnectionState.error:
        return 'Error';
    }
  }

  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting => this == ConnectionState.connecting;
  bool get isDisconnected => this == ConnectionState.disconnected;
}
