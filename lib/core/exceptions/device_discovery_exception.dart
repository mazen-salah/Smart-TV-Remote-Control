/// Excepción base para errores de descubrimiento de dispositivos
abstract class DeviceDiscoveryException implements Exception {
  final String message;
  
  const DeviceDiscoveryException(this.message);
  
  @override
  String toString() => '$runtimeType: $message';
}

/// No se encontraron dispositivos
class NoDevicesFoundException extends DeviceDiscoveryException {
  const NoDevicesFoundException() : super(
    'No se encontraron TVs en la red.\n\n'
    'Verifica que:\n'
    '• Tu TV esté encendida\n'
    '• Ambos dispositivos estén en la misma red WiFi\n'
    '• El protocolo UPnP esté habilitado en tu router\n'
    '• Tu TV tenga habilitada la función de red'
  );
}

/// Error durante el proceso de descubrimiento
class DiscoveryFailedException extends DeviceDiscoveryException {
  const DiscoveryFailedException(String message) : super(message);
}

/// Error de permisos de red
class NetworkPermissionException extends DeviceDiscoveryException {
  const NetworkPermissionException() : super(
    'Permisos de red insuficientes para descubrir dispositivos'
  );
}

/// Error de timeout en descubrimiento
class DiscoveryTimeoutException extends DeviceDiscoveryException {
  const DiscoveryTimeoutException() : super(
    'Timeout durante el descubrimiento de dispositivos'
  );
}

