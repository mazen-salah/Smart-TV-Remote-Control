// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Comando para Smart TV';

  @override
  String get selectDevice => 'Escolher dispositivo';

  @override
  String get addManually => 'Adicionar manualmente';

  @override
  String get addTvManually => 'Adicionar TV manualmente';

  @override
  String get tvIpAddress => 'Endereço IP da TV';

  @override
  String get nameOptional => 'Nome (opcional)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Adicionar';

  @override
  String get scanning => 'A procurar na rede…';

  @override
  String get devicesFound => 'Dispositivos encontrados';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos encontrados',
      one: '$count dispositivo encontrado',
      zero: 'Nenhum dispositivo encontrado',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Nenhum dispositivo encontrado';

  @override
  String get noDevicesHint =>
      'Verifique se a TV está ligada\ne na mesma rede Wi-Fi';

  @override
  String get discoveryFailed => 'Falha na procura';

  @override
  String get scanAgain => 'Procurar novamente';

  @override
  String get noWifi => 'Sem ligação Wi-Fi';

  @override
  String get noWifiHint =>
      'Ligue-se a uma rede Wi-Fi para a aplicação conseguir falar com a TV.';

  @override
  String get wifiReconnected => 'Wi-Fi ligado novamente';

  @override
  String get wifiDisconnected => 'Wi-Fi desligado — verifique a ligação';

  @override
  String get remote => 'Comando';

  @override
  String get reconnect => 'Voltar a ligar';

  @override
  String get numericKeypad => 'Teclado numérico';

  @override
  String get power => 'Energia';

  @override
  String get connecting => 'A ligar…';

  @override
  String get reconnecting => 'A religar…';

  @override
  String get connected => 'Ligado';

  @override
  String get connectionError => 'Erro de ligação';

  @override
  String get disconnected => 'Desligado';

  @override
  String get idle => 'Inativo';

  @override
  String disconnectedReason(String reason) {
    return 'Desligado: $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Voltar';

  @override
  String get exit => 'Sair';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'Entrada';

  @override
  String get up => 'Cima';

  @override
  String get down => 'Baixo';

  @override
  String get left => 'Esquerda';

  @override
  String get right => 'Direita';

  @override
  String get volumeUp => 'Aumentar volume';

  @override
  String get volumeDown => 'Baixar volume';

  @override
  String get mute => 'Sem som';

  @override
  String get channelUp => 'Canal seguinte';

  @override
  String get channelDown => 'Canal anterior';

  @override
  String get menu => 'Menu';

  @override
  String get more => 'Mais';

  @override
  String get rewind => 'Retroceder';

  @override
  String get record => 'Gravar';

  @override
  String get play => 'Reproduzir';

  @override
  String get stop => 'Parar';

  @override
  String get pause => 'Pausa';

  @override
  String get fastForward => 'Avançar';

  @override
  String get redButton => 'Botão vermelho';

  @override
  String get greenButton => 'Botão verde';

  @override
  String get yellowButton => 'Botão amarelo';

  @override
  String get blueButton => 'Botão azul';

  @override
  String get invalidIpv4 => 'Endereço IPv4 inválido';

  @override
  String get enterIpAddress => 'Introduza um endereço IP';

  @override
  String get lookingForTvs => 'À procura de TVs…';

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
  String get inputSource => 'Fonte de entrada';

  @override
  String get unknown => 'desconhecido';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'TV da sala';

  @override
  String get forgetTv => 'Esquecer esta TV';

  @override
  String forgetTvConfirm(String name) {
    return 'Remover $name e o emparelhamento? Terá de autorizar a aplicação na TV outra vez.';
  }

  @override
  String get forget => 'Esquecer';

  @override
  String connectionFailed(String reason) {
    return 'Não foi possível ligar: $reason';
  }
}
