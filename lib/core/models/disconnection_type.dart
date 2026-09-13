enum DisconnectionType {
  wifiDisconnected,
  tvPowerOff,
  unknown,
  userInitiated,
  networkError,
  authenticationFailed,
}

extension DisconnectionTypeExtension on DisconnectionType {
  String get displayName {
    switch (this) {
      case DisconnectionType.wifiDisconnected:
        return 'Wi-Fi disconnected';
      case DisconnectionType.tvPowerOff:
        return 'TV powered off';
      case DisconnectionType.unknown:
        return 'Unknown';
      case DisconnectionType.userInitiated:
        return 'Disconnected by user';
      case DisconnectionType.networkError:
        return 'Network error';
      case DisconnectionType.authenticationFailed:
        return 'Authentication failed';
    }
  }

  bool get isRecoverable {
    switch (this) {
      case DisconnectionType.wifiDisconnected:
      case DisconnectionType.networkError:
        return true;
      case DisconnectionType.tvPowerOff:
      case DisconnectionType.userInitiated:
      case DisconnectionType.authenticationFailed:
      case DisconnectionType.unknown:
        return false;
    }
  }
}
