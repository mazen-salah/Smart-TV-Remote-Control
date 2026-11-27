import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/roku/roku_buttons.dart';
import 'package:xml/xml.dart';

/// What `/query/device-info` tells us about a Roku device.
class RokuDeviceInfo {
  const RokuDeviceInfo({this.name, this.model, this.mac, this.serial});

  final String? name;
  final String? model;
  final String? mac;
  final String? serial;
}

/// Client for Roku's External Control Protocol.
///
/// ECP is plain HTTP on port 8060: `POST /keypress/<Key>` presses a button and
/// `GET /query/device-info` returns an XML description of the device. There is
/// no pairing, no session and no token — the device answers as long as
/// *Settings → System → Advanced system settings → Control by mobile apps →
/// Network access* is "Enabled".
class RokuTvService {
  RokuTvService({
    required this.host,
    this.port = defaultPort,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const int defaultPort = 8060;
  static const Duration kTimeout = Duration(seconds: 5);

  final String host;
  final int port;
  final http.Client _client;

  bool _connected = false;
  String? _mac;
  String? _deviceName;
  String? _modelName;
  String? _serialNumber;

  bool get isConnected => _connected;
  String? get mac => _mac;
  String? get deviceName => _deviceName;
  String? get modelName => _modelName;
  String? get serialNumber => _serialNumber;

  void Function(DisconnectionType)? onDisconnected;

  Uri _uri(String path) => Uri.parse('http://$host:$port$path');

  /// Fetches the device description; a failure here means the device is not
  /// reachable or ECP is switched off, which is what the user needs to know.
  Future<void> connect() async {
    final info = await _fetchDeviceInfo();
    _deviceName = info.name;
    _modelName = info.model;
    _mac = info.mac;
    _serialNumber = info.serial;
    _connected = true;
  }

  void disconnect() {
    _connected = false;
    _client.close();
  }

  Future<void> ensureConnection() async {
    if (!_connected) await connect();
  }

  Future<void> sendKey(KeyCodes key) async {
    if (key == KeyCodes.KEY_POWER) {
      await power();
      return;
    }
    final name = rokuKeyFor(key);
    if (name == null) {
      log('Roku: no ECP key for ${key.name}, ignored');
      return;
    }
    await post('/keypress/$name');
  }

  /// Roku has separate power keys and no toggle over ECP; the app's power
  /// button means "off", and Wake-on-LAN brings a TV model back.
  Future<void> power() => post('/keypress/PowerOff');

  /// `POST` with no body, as ECP expects. Throws if the device answers with
  /// anything but 200, which is what a wrong key name or a closed port does.
  Future<void> post(String path) async {
    final http.Response response;
    try {
      response = await _client.post(_uri(path)).timeout(kTimeout);
    } on Exception catch (e) {
      _handleTransportError(e);
      rethrow;
    }
    if (response.statusCode != 200) {
      throw HttpException(
        'Roku answered ${response.statusCode} for $path',
        uri: _uri(path),
      );
    }
  }

  /// Launches an installed app by its channel id (`POST /launch/<id>`).
  Future<void> launchApp(String appId) => post('/launch/$appId');

  Future<RokuDeviceInfo> _fetchDeviceInfo() async {
    final uri = _uri('/query/device-info');
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(kTimeout);
    } on Exception catch (e) {
      _handleTransportError(e);
      rethrow;
    }
    if (response.statusCode != 200) {
      throw HttpException(
        'Roku answered ${response.statusCode} for /query/device-info',
        uri: uri,
      );
    }

    final XmlDocument document;
    try {
      document = XmlDocument.parse(response.body);
    } on XmlParserException catch (e) {
      throw FormatException(
        'Roku sent a device description we cannot read: $e',
      );
    }

    String? tag(String name) {
      for (final element in document.findAllElements(name)) {
        final value = element.innerText.trim();
        if (value.isNotEmpty) return value;
      }
      return null;
    }

    return RokuDeviceInfo(
      name: tag('user-device-name') ?? tag('friendly-device-name'),
      model: tag('model-name'),
      // Wi-Fi models report one of these, a wired set the other.
      mac: tag('wifi-mac') ?? tag('ethernet-mac'),
      serial: tag('serial-number'),
    );
  }

  void _handleTransportError(Object error) {
    log('Roku is unreachable: $error');
    if (!_connected) return;
    _connected = false;
    onDisconnected?.call(DisconnectionType.networkError);
  }
}
