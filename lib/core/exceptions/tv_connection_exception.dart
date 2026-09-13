/// Excepción base para errores de conexión con TV
abstract class TVConnectionException implements Exception {
  const TVConnectionException(this.message, {this.deviceHost, this.deviceName});
  final String message;
  final String? deviceHost;
  final String? deviceName;

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
    super.message, {
    super.deviceHost,
    super.deviceName,
  });
}

/// Error al enviar comando al TV
class TVCommandException extends TVConnectionException {
  const TVCommandException(super.message, {super.deviceHost, super.deviceName});
}

/// Error de autenticación con el TV
class TVAuthenticationException extends TVConnectionException {
  const TVAuthenticationException(
    super.message, {
    super.deviceHost,
    super.deviceName,
  });
}

/// Error de timeout en operaciones con TV
class TVTimeoutException extends TVConnectionException {
  const TVTimeoutException(super.message, {super.deviceHost, super.deviceName});
}
