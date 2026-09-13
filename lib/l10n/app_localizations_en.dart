// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart TV Remote';

  @override
  String get selectDevice => 'Select Device';

  @override
  String get addManually => 'Add manually';

  @override
  String get addTvManually => 'Add TV manually';

  @override
  String get tvIpAddress => 'TV IP address';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get scanning => 'Scanning network…';

  @override
  String get devicesFound => 'Devices found';

  @override
  String foundCount(int count) {
    return 'Found $count device(s)';
  }

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get noDevicesHint =>
      'Make sure your TV is powered on\nand on the same Wi-Fi network';

  @override
  String get discoveryFailed => 'Discovery failed';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get noWifi => 'No Wi-Fi connection';

  @override
  String get noWifiHint =>
      'Connect to a Wi-Fi network so the app can talk to your TV.';

  @override
  String get wifiReconnected => 'Wi-Fi reconnected';

  @override
  String get wifiDisconnected => 'Wi-Fi disconnected — check your connection';

  @override
  String get remote => 'Remote';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get numericKeypad => 'Numeric keypad';

  @override
  String get power => 'Power';

  @override
  String get connecting => 'Connecting…';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get connected => 'Connected';

  @override
  String get connectionError => 'Connection error';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get idle => 'Idle';

  @override
  String disconnectedReason(String reason) {
    return 'Disconnected: $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get exit => 'Exit';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'Input';

  @override
  String get up => 'Up';

  @override
  String get down => 'Down';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get volumeUp => 'Volume up';

  @override
  String get volumeDown => 'Volume down';

  @override
  String get mute => 'Mute';

  @override
  String get channelUp => 'Channel up';

  @override
  String get channelDown => 'Channel down';

  @override
  String get menu => 'Menu';

  @override
  String get more => 'More';

  @override
  String get rewind => 'Rewind';

  @override
  String get record => 'Record';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get fastForward => 'Fast forward';

  @override
  String get redButton => 'Red button';

  @override
  String get greenButton => 'Green button';

  @override
  String get yellowButton => 'Yellow button';

  @override
  String get blueButton => 'Blue button';

  @override
  String get invalidIpv4 => 'Invalid IPv4 address';

  @override
  String get enterIpAddress => 'Enter an IP address';

  @override
  String get lookingForTvs => 'Looking for TVs…';

  @override
  String get brand => 'Brand';

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
  String get smartHub => 'Smart hub';

  @override
  String get inputSource => 'Input source';

  @override
  String get unknown => 'unknown';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'Living-room TV';
}
