/// Excepción base para errores de conexión con TV
abstract class TVConnectionException implements Exception {
  final String message;
  final String? deviceHost;
  final String? deviceName;
  
  const TVConnectionException(
    this.message, {
    this.deviceHost,
    this.deviceName,
  });
  
  @override
  String toString() {
    final deviceInfo = deviceName != null ? ' ($deviceName)' : '';
    final hostInfo = deviceHost != null ? ' en $deviceHost' : '';
    return '$runtimeType: $message$deviceInfo$hostInfo';
  }
}

/// Error al conectar con el TV
class TVConnectionFailedException extends TVConnectionException {
  const TVConnectionFailedException(
    String message, {
    String? deviceHost,
    String? deviceName,
  }) : super(message, deviceHost: deviceHost, deviceName: deviceName);
}

/// Error al enviar comando al TV
class TVCommandException extends TVConnectionException {
  const TVCommandException(
    String message, {
    String? deviceHost,
    String? deviceName,
  }) : super(message, deviceHost: deviceHost, deviceName: deviceName);
}

/// Error de autenticación con el TV
class TVAuthenticationException extends TVConnectionException {
  const TVAuthenticationException(
    String message, {
    String? deviceHost,
    String? deviceName,
  }) : super(message, deviceHost: deviceHost, deviceName: deviceName);
}

/// Error de timeout en operaciones con TV
class TVTimeoutException extends TVConnectionException {
  const TVTimeoutException(
    String message, {
    String? deviceHost,
    String? deviceName,
  }) : super(message, deviceHost: deviceHost, deviceName: deviceName);
}

