// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Smart-TV-Fernbedienung';

  @override
  String get selectDevice => 'Gerät auswählen';

  @override
  String get addManually => 'Manuell hinzufügen';

  @override
  String get addTvManually => 'TV manuell hinzufügen';

  @override
  String get tvIpAddress => 'IP-Adresse des TVs';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get scanning => 'Netzwerk wird durchsucht…';

  @override
  String get devicesFound => 'Gefundene Geräte';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Geräte gefunden',
      one: '$count Gerät gefunden',
      zero: 'Keine Geräte gefunden',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Keine Geräte gefunden';

  @override
  String get noDevicesHint =>
      'Prüfen Sie, ob der TV eingeschaltet und\nim selben WLAN ist';

  @override
  String get discoveryFailed => 'Suche fehlgeschlagen';

  @override
  String get scanAgain => 'Erneut suchen';

  @override
  String get noWifi => 'Keine WLAN-Verbindung';

  @override
  String get noWifiHint =>
      'Verbinden Sie sich mit einem WLAN, damit die App den TV erreichen kann.';

  @override
  String get wifiReconnected => 'WLAN wieder verbunden';

  @override
  String get wifiDisconnected => 'WLAN getrennt — Verbindung prüfen';

  @override
  String get remote => 'Fernbedienung';

  @override
  String get reconnect => 'Neu verbinden';

  @override
  String get numericKeypad => 'Zifferntastatur';

  @override
  String get power => 'Ein/Aus';

  @override
  String get connecting => 'Verbinden…';

  @override
  String get reconnecting => 'Neu verbinden…';

  @override
  String get connected => 'Verbunden';

  @override
  String get connectionError => 'Verbindungsfehler';

  @override
  String get disconnected => 'Getrennt';

  @override
  String get idle => 'Inaktiv';

  @override
  String disconnectedReason(String reason) {
    return 'Getrennt: $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Zurück';

  @override
  String get exit => 'Beenden';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'Eingang';

  @override
  String get up => 'Oben';

  @override
  String get down => 'Unten';

  @override
  String get left => 'Links';

  @override
  String get right => 'Rechts';

  @override
  String get volumeUp => 'Lauter';

  @override
  String get volumeDown => 'Leiser';

  @override
  String get mute => 'Stumm';

  @override
  String get channelUp => 'Nächster Sender';

  @override
  String get channelDown => 'Vorheriger Sender';

  @override
  String get menu => 'Menü';

  @override
  String get more => 'Mehr';

  @override
  String get rewind => 'Zurückspulen';

  @override
  String get record => 'Aufnehmen';

  @override
  String get play => 'Wiedergabe';

  @override
  String get stop => 'Stopp';

  @override
  String get pause => 'Pause';

  @override
  String get fastForward => 'Vorspulen';

  @override
  String get redButton => 'Rote Taste';

  @override
  String get greenButton => 'Grüne Taste';

  @override
  String get yellowButton => 'Gelbe Taste';

  @override
  String get blueButton => 'Blaue Taste';

  @override
  String get invalidIpv4 => 'Ungültige IPv4-Adresse';

  @override
  String get enterIpAddress => 'IP-Adresse eingeben';

  @override
  String get lookingForTvs => 'TVs werden gesucht…';

  @override
  String get brand => 'Marke';

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
  String get inputSource => 'Eingangsquelle';

  @override
  String get unknown => 'unbekannt';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'TV im Wohnzimmer';

  @override
  String get forgetTv => 'Diesen TV entfernen';

  @override
  String forgetTvConfirm(String name) {
    return '$name und die Kopplung entfernen? Sie müssen die App am TV erneut erlauben.';
  }

  @override
  String get forget => 'Entfernen';

  @override
  String connectionFailed(String reason) {
    return 'Verbindung fehlgeschlagen: $reason';
  }
}
