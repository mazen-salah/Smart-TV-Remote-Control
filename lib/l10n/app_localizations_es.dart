// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Control Remoto Smart TV';

  @override
  String get selectDevice => 'Seleccionar Dispositivo';

  @override
  String get addManually => 'Agregar manualmente';

  @override
  String get addTvManually => 'Agregar TV manualmente';

  @override
  String get tvIpAddress => 'Dirección IP del TV';

  @override
  String get nameOptional => 'Nombre (opcional)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Agregar';

  @override
  String get scanning => 'Escaneando red…';

  @override
  String get devicesFound => 'Dispositivos encontrados';

  @override
  String foundCount(int count) {
    return 'Se encontraron $count dispositivo(s)';
  }

  @override
  String get noDevicesFound => 'No se encontraron dispositivos';

  @override
  String get noDevicesHint =>
      'Verifica que tu TV esté encendida\ny conectada a la misma red Wi-Fi';

  @override
  String get discoveryFailed => 'Error al buscar dispositivos';

  @override
  String get scanAgain => 'Buscar de nuevo';

  @override
  String get noWifi => 'Sin conexión Wi-Fi';

  @override
  String get noWifiHint => 'Conéctate a una red Wi-Fi para hablar con tu TV.';

  @override
  String get wifiReconnected => 'Wi-Fi reconectado';

  @override
  String get wifiDisconnected => 'Wi-Fi desconectado — verifica tu conexión';

  @override
  String get remote => 'Control Remoto';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get numericKeypad => 'Teclado numérico';

  @override
  String get power => 'Encendido';

  @override
  String get connecting => 'Conectando…';

  @override
  String get reconnecting => 'Reconectando…';

  @override
  String get connected => 'Conectado';

  @override
  String get connectionError => 'Error de conexión';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get idle => 'Inactivo';

  @override
  String disconnectedReason(String reason) {
    return 'Desconectado: $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Atrás';

  @override
  String get exit => 'Salir';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'Entrada';

  @override
  String get up => 'Arriba';

  @override
  String get down => 'Abajo';

  @override
  String get left => 'Izquierda';

  @override
  String get right => 'Derecha';

  @override
  String get volumeUp => 'Subir volumen';

  @override
  String get volumeDown => 'Bajar volumen';

  @override
  String get mute => 'Silenciar';

  @override
  String get channelUp => 'Canal siguiente';

  @override
  String get channelDown => 'Canal anterior';

  @override
  String get menu => 'Menú';

  @override
  String get more => 'Más';

  @override
  String get rewind => 'Retroceder';

  @override
  String get record => 'Grabar';

  @override
  String get play => 'Reproducir';

  @override
  String get stop => 'Detener';

  @override
  String get pause => 'Pausar';

  @override
  String get fastForward => 'Adelantar';

  @override
  String get redButton => 'Botón rojo';

  @override
  String get greenButton => 'Botón verde';

  @override
  String get yellowButton => 'Botón amarillo';

  @override
  String get blueButton => 'Botón azul';

  @override
  String get invalidIpv4 => 'Dirección IPv4 inválida';

  @override
  String get enterIpAddress => 'Ingresa una dirección IP';

  @override
  String get lookingForTvs => 'Buscando TVs…';

  @override
  String get brand => 'Marca';

  @override
  String get brandSamsung => 'Samsung';

  @override
  String get brandLg => 'LG';

  @override
  String ipLabel(String host) {
    return 'IP: $host';
  }

  @override
  String macLabel(String mac) {
    return 'MAC: $mac';
  }

  @override
  String get smartHub => 'Smart Hub';

  @override
  String get inputSource => 'Fuente de entrada';

  @override
  String get unknown => 'desconocido';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'TV de la sala';
}
