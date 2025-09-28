import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:upnp2/upnp.dart';
import 'package:web_socket_channel/io.dart';

const int kConnectionTimeout = 60;
const kKeyDelay = 200;
const kWakeOnLanDelay = 5000;
const kUpnpTimeout = 1000;

enum DisconnectionType {
  wifiDisconnected,
  tvPowerOff,
  unknown
}

class SmartTV {
  final List<Map<String, dynamic>> services;
  final String? host;
  final String? mac;
  final String? deviceName;
  final String? modelName;
  final String api;
  final String wsapi;
  bool isConnected = false;

  String? token;
  Response? info;
  IOWebSocketChannel? ws;
  Timer? timer;
  Timer? _heartbeatTimer;
  Timer? _connectionCheckTimer;
  Function(DisconnectionType)? onDisconnected;

  SmartTV({
    this.host,
    this.mac,
    this.deviceName,
    this.modelName,
  })  : api = "http://$host:8001/api/v2/",
        wsapi = "wss://$host:8002/api/v2/",
        services = [];

  addService(service) {
    services.add(service);
  }

  setOnDisconnectedCallback(Function(DisconnectionType) callback) {
    onDisconnected = callback;
  }

  connect({appName = 'DartSamsungSmartTVDriver'}) async {
    var completer = Completer();

    if (isConnected) {
      log('Already connected to device');
      completer.complete();
      return completer.future;
    }

    try {
      info = await getDeviceInfo();
      // log (json.decode(info!.body).toString());

      final appNameBase64 = base64.encode(utf8.encode(appName));
      String channel =
          "${wsapi}channels/samsung.remote.control?name=$appNameBase64";
      if (token != null) {
        channel += '&token=$token';
        log("Using token $token");
      }

      log("Connecting to $channel");
      ws = IOWebSocketChannel.connect(
        Uri.parse(channel),
        customClient: HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true,
      );

      ws?.stream.listen((message) {
        Map<String, dynamic> data;
        try {
          data = json.decode(message);
          log ("data $data");
        } catch (e) {
          log('Could not parse TV response $message');
          completer.completeError('Could not parse TV response: $e');
          return;
        }

        if (data["data"] != null && data["data"]["token"] != null) {
          token = data["data"]["token"];
          log("Token updated: $token");
        }

        if (data["event"] == 'ms.channel.connect') {
          log('Connection successfully established');
          isConnected = true;
          _startHeartbeat();
          _startConnectionCheck();
          completer.complete();
        } else {
          log('TV responded with $data');
        }
      }, onError: (error) {
        log('WebSocket error: $error');
        _handleDisconnection();
        completer.completeError('WebSocket connection failed: $error');
      }, onDone: () {
        log('WebSocket connection closed');
        _handleDisconnection();
      });

      // Set a timeout for connection
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError('Connection timeout');
        }
      });

    } catch (e) {
      log('Connection error: $e');
      completer.completeError('Failed to connect: $e');
    }

    return completer.future;
  }

  Future<http.Response> getDeviceInfo() async {
    log("Getting device info from $api");
    return http.get(Uri.parse(api));
  }

  disconnect() {
    _stopHeartbeat();
    _stopConnectionCheck();
    ws?.sink.close();
    isConnected = false;
    log('Disconnected from device');
  }

  void _startHeartbeat() {
    _stopHeartbeat(); // Stop any existing heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isConnected && ws != null) {
        try {
          // Just check if WebSocket is still open, don't send commands
          if (ws!.closeCode != null) {
            log('WebSocket closed detected in heartbeat');
            _handleDisconnection();
          } else {
            log('Heartbeat check - connection still active');
          }
        } catch (e) {
          log('Heartbeat failed: $e');
          _handleDisconnection();
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startConnectionCheck() {
    _stopConnectionCheck(); // Stop any existing connection check
    _connectionCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (isConnected && ws != null) {
        // Check if WebSocket is still open
        if (ws!.closeCode != null) {
          log('WebSocket closed detected in connection check');
          _handleDisconnection();
        }
      }
    });
  }

  void _stopConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  Future<DisconnectionType> _detectDisconnectionType() async {
    log('Starting disconnection type detection...');
    log('TV host: $host');
    
    // Since we're automatically triggering disconnection for power button,
    // we can assume it's TV power off when called from sendKey
    log('Assuming TV power off for automatic disconnection');
    return DisconnectionType.tvPowerOff;
  }

  void _handleDisconnection() {
    log('_handleDisconnection called - isConnected: $isConnected');
    if (isConnected) {
      log('Connection lost - handling disconnection immediately');
      log('Before cleanup - WebSocket closeCode: ${ws?.closeCode}');
      
      isConnected = false;
      _stopHeartbeat();
      _stopConnectionCheck();
      ws?.sink.close();
      ws = null;
      
      log('After cleanup - WebSocket closed, starting disconnection type detection...');
      
      // Detect the type of disconnection asynchronously
      _detectDisconnectionType().then((disconnectionType) {
        log('Disconnection type detected: $disconnectionType');
        
        // Call the disconnection callback if set
        if (onDisconnected != null) {
          log('Calling disconnection callback with type: $disconnectionType');
          onDisconnected!(disconnectionType);
        } else {
          log('No disconnection callback set!');
        }
      }).catchError((e) {
        log('Error in disconnection detection: $e');
        // Fallback to unknown type
        if (onDisconnected != null) {
          log('Using fallback unknown disconnection type');
          onDisconnected!(DisconnectionType.unknown);
        }
      });
    } else {
      log('Already disconnected, skipping disconnection handling');
    }
  }

  bool get connectionStatus => isConnected && ws != null;

  Future<void> ensureConnection() async {
    if (!connectionStatus) {
      log('Ensuring connection to device...');
      await connect();
      if (!connectionStatus) {
        throw Exception('Failed to establish connection to device');
      }
    }
  }

  sendKey(KeyCodes key) async {
    try {
      await ensureConnection();
      
      final keyName = key.toString().split('.').last;
      log("Send key command: $keyName");
      
      final data = json.encode({
        "method": 'ms.remote.control',
        "params": {
          "Cmd": 'Click',
          "DataOfCmd": keyName,
          "Option": false,
          "TypeOfRemote": 'SendRemoteKey',
        }
      });

      // Check if WebSocket is still connected before sending
      if (ws == null || ws!.closeCode != null) {
        log('WebSocket is closed, handling disconnection');
        _handleDisconnection();
        throw Exception('WebSocket connection is closed');
      }

      try {
        ws?.sink.add(data);
        log("Key command sent successfully: $keyName");
      } catch (e) {
        log('Failed to send data to WebSocket: $e');
        _handleDisconnection();
        throw Exception('Failed to send data to WebSocket: $e');
      }
      
      return Future.delayed(const Duration(milliseconds: kKeyDelay));
    } catch (e) {
      log('Error sending key command: $e');
      // If connection fails, handle disconnection immediately
      _handleDisconnection();
      throw Exception('Failed to send key command: $e');
    }
  }

  static discover() async {
    final devices = await discoverAll();
    if (devices.isEmpty) {
      throw Exception(
          "No se encontraron TVs Samsung en la red.\n\n"
          "Verifica que:\n"
          "• Tu TV Samsung esté encendida\n"
          "• Ambos dispositivos estén en la misma red WiFi\n"
          "• El protocolo UPnP esté habilitado en tu router\n"
          "• Tu TV tenga habilitada la función 'Smart View' o 'Screen Mirroring'");
    }
    return devices.first;
  }

  static Future<List<SmartTV>> discoverAll() async {
    var completer = Completer<List<SmartTV>>();
    final List<SmartTV> tvs = [];

    final client = DeviceDiscoverer();
    await client.start(ipv6: false);

    // Set a timeout for discovery
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(tvs);
      }
    });

    client.quickDiscoverClients().listen((client) async {
      RegExp re = RegExp(r'^.*?Samsung.+UPnP.+SDK\/1\.0$');

      if (!re.hasMatch(client.server!)) {
        log("Ignoring ${client.server}");
        return;
      }
      try {
        final device = await client.getDevice();
        Uri location = Uri.parse(client.location!);
        final deviceExists = tvs.firstWhere((tv) => tv.host == location.host,
            orElse: () => SmartTV(host: null));
        if (deviceExists.host == null) {
          log("Found ${device?.friendlyName} on IP ${location.host}");
          final tv = SmartTV(
            host: location.host,
            deviceName: device?.friendlyName,
            modelName: device?.modelName,
          );
          tv.addService({
            "location": client.location,
            "server": client.server,
            "st": client.st,
            "usn": client.usn
          });
          tvs.add(tv);
        }
      } catch (e, stack) {
        log("ERROR: $e - ${client.location}");
        log(stack as String);
      }
    }).onDone(() {
      if (!completer.isCompleted) {
        completer.complete(tvs);
      }
    });

    return completer.future;
  }
}
