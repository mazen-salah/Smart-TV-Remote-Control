enum DisconnectionType {
  wifiDisconnected,
  tvPowerOff,
  unknown,
  userInitiated,
  networkError,
  authenticationFailed
}

extension DisconnectionTypeExtension on DisconnectionType {
  String get displayName {
    switch (this) {
      case DisconnectionType.wifiDisconnected:
        return 'WiFi Desconectado';
      case DisconnectionType.tvPowerOff:
        return 'TV Apagado';
      case DisconnectionType.unknown:
        return 'Desconexión Desconocida';
      case DisconnectionType.userInitiated:
        return 'Desconexión Manual';
      case DisconnectionType.networkError:
        return 'Error de Red';
      case DisconnectionType.authenticationFailed:
        return 'Error de Autenticación';
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

