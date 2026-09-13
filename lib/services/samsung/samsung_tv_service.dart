import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:upnp2/upnp.dart';
import 'package:web_socket_channel/io.dart';

const Duration kConnectionTimeout = Duration(seconds: 10);
const Duration kKeyDelay = Duration(milliseconds: 200);
const Duration kPingInterval = Duration(seconds: 10);
const Duration kDiscoveryTimeout = Duration(seconds: 10);

class SamsungTVService {
  SamsungTVService({
    this.host,
    String? mac,
    this.deviceName,
    this.modelName,
    String? token,
  })  : api = 'http://$host:8001/api/v2/',
        wsapi = 'wss://$host:8002/api/v2/',
        _mac = mac,
        _token = token;

  final String? host;
  String? _mac;
  final String? deviceName;
  final String? modelName;
  final String api;
  final String wsapi;

  String? get mac => _mac;

  bool _isConnected = false;
  String? _token;
  http.Response? _info;
  IOWebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;

  void Function(DisconnectionType)? onDisconnected;
  void Function(String token)? onTokenReceived;

  bool get isConnected => _isConnected;
  bool get connectionStatus => _isConnected && _ws != null;
  String? get token => _token;
  http.Response? get info => _info;

  void setOnDisconnectedCallback(void Function(DisconnectionType) callback) {
    onDisconnected = callback;
  }

  void setOnTokenReceivedCallback(void Function(String token) callback) {
    onTokenReceived = callback;
  }

  Future<void> connect({String appName = 'DartSamsungSmartTVDriver'}) async {
    if (_isConnected) {
      log('Already connected to device');
      return;
    }

    final completer = Completer<void>();

    try {
      _info = await getDeviceInfo();
      _extractMacFromInfo();

      final appNameBase64 = base64.encode(utf8.encode(appName));
      var channel =
          '${wsapi}channels/samsung.remote.control?name=$appNameBase64';
      if (_token != null) {
        channel += '&token=$_token';
        log('Using stored token');
      }

      log('Connecting to $channel');
      _ws = IOWebSocketChannel.connect(
        Uri.parse(channel),
        pingInterval: kPingInterval,
        customClient: HttpClient()
          ..badCertificateCallback = (cert, host, port) => true,
      );

      _wsSub = _ws!.stream.listen(
        (dynamic message) {
          Map<String, dynamic> data;
          try {
            data = json.decode(message as String) as Map<String, dynamic>;
          } catch (e) {
            log('Could not parse TV response $message');
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('Could not parse TV response: $e'),
              );
            }
            return;
          }

          final payload = data['data'];
          if (payload is Map && payload['token'] != null) {
            final newToken = payload['token'] as String;
            _token = newToken;
            log('Token received');
            onTokenReceived?.call(newToken);
          }

          if (data['event'] == 'ms.channel.connect') {
            log('Connection successfully established');
            _isConnected = true;
            if (!completer.isCompleted) completer.complete();
          } else if (data['event'] == 'ms.channel.unauthorized') {
            log('TV rejected the connection (unauthorized)');
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('TV rejected the connection (unauthorized)'),
              );
            }
            _handleDisconnection(DisconnectionType.authenticationFailed);
          } else {
            log('TV responded with $data');
          }
        },
        onError: (Object error) {
          log('WebSocket error: $error');
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('WebSocket connection failed: $error'),
            );
          }
          _handleDisconnection(_classifyError(error));
        },
        onDone: () {
          log('WebSocket closed (code=${_ws?.closeCode})');
          if (!completer.isCompleted) {
            completer
                .completeError(Exception('WebSocket closed before connect'));
          }
          _handleDisconnection(DisconnectionType.tvPowerOff);
        },
      );

      Timer(kConnectionTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Connection timeout'));
        }
      });
    } catch (e) {
      log('Connection error: $e');
      if (!completer.isCompleted) {
        completer.completeError(Exception('Failed to connect: $e'));
      }
    }

    return await completer.future;
  }

  Future<http.Response> getDeviceInfo() {
    log('Getting device info from $api');
    return http.get(Uri.parse(api)).timeout(kConnectionTimeout);
  }

  void _extractMacFromInfo() {
    final body = _info?.body;
    if (body == null || body.isEmpty) return;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final device = json['device'];
      if (device is Map<String, dynamic>) {
        final wifiMac = device['wifiMac'] as String?;
        if (wifiMac != null && wifiMac.isNotEmpty) {
          _mac = wifiMac;
          log('Extracted MAC from device info: $wifiMac');
        }
      }
    } catch (e) {
      log('Could not parse device info for MAC: $e');
    }
  }

  void disconnect() {
    if (!_isConnected && _ws == null) return;
    _isConnected = false;
    unawaited(_wsSub?.cancel());
    _wsSub = null;
    unawaited(_ws?.sink.close());
    _ws = null;
    log('Disconnected from device');
  }

  DisconnectionType _classifyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('connection refused') || msg.contains('errno = 111')) {
      return DisconnectionType.tvPowerOff;
    }
    if (msg.contains('no route to host') ||
        msg.contains('host unreachable') ||
        msg.contains('network is unreachable')) {
      return DisconnectionType.networkError;
    }
    if (msg.contains('unauthorized')) {
      return DisconnectionType.authenticationFailed;
    }
    return DisconnectionType.unknown;
  }

  void _handleDisconnection(DisconnectionType type) {
    if (!_isConnected && _ws == null) {
      // Already cleaned up
      return;
    }
    log('Handling disconnection: $type');
    _isConnected = false;
    unawaited(_wsSub?.cancel());
    _wsSub = null;
    unawaited(_ws?.sink.close());
    _ws = null;
    onDisconnected?.call(type);
  }

  Future<void> ensureConnection() async {
    if (!connectionStatus) {
      log('Ensuring connection to device...');
      await connect();
      if (!connectionStatus) {
        throw Exception('Failed to establish connection to device');
      }
    }
  }

  Future<void> sendKey(KeyCodes key) async {
    await ensureConnection();

    final keyName = key.toString().split('.').last;
    log('Sending key: $keyName');

    final data = json.encode({
      'method': 'ms.remote.control',
      'params': {
        'Cmd': 'Click',
        'DataOfCmd': keyName,
        'Option': false,
        'TypeOfRemote': 'SendRemoteKey',
      },
    });

    final ws = _ws;
    if (ws == null || ws.closeCode != null) {
      _handleDisconnection(DisconnectionType.networkError);
      throw Exception('WebSocket connection is closed');
    }

    try {
      ws.sink.add(data);
    } catch (e) {
      log('Failed to send key: $e');
      _handleDisconnection(_classifyError(e));
      throw Exception('Failed to send key: $e');
    }

    await Future<void>.delayed(kKeyDelay);
  }

  static Future<SamsungTVService> discover() async {
    final devices = await discoverAll();
    if (devices.isEmpty) {
      throw Exception('No Samsung TVs found on the network');
    }
    return devices.first;
  }

  static Future<List<SamsungTVService>> discoverAll() async {
    final completer = Completer<List<SamsungTVService>>();
    final tvs = <SamsungTVService>[];
    final samsungRegex = RegExp(r'^.*?Samsung.+UPnP.+SDK\/1\.0$');

    final client = DeviceDiscoverer();
    await client.start(ipv6: false);

    Timer(kDiscoveryTimeout, () {
      if (!completer.isCompleted) completer.complete(tvs);
    });

    client.quickDiscoverClients().listen(
      (client) async {
        if (client.server == null || !samsungRegex.hasMatch(client.server!)) {
          return;
        }
        try {
          final device = await client.getDevice();
          final location = Uri.parse(client.location!);
          final alreadyKnown = tvs.any((tv) => tv.host == location.host);
          if (!alreadyKnown) {
            log('Found ${device?.friendlyName} on IP ${location.host}');
            tvs.add(
              SamsungTVService(
                host: location.host,
                deviceName: device?.friendlyName,
                modelName: device?.modelName,
              ),
            );
          }
        } catch (e, stack) {
          log('Discovery error: $e\n$stack');
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(tvs);
      },
    );

    return await completer.future;
  }
}
