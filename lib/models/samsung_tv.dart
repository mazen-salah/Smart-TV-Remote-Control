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

class SmartTV {
  final List<Map<String, dynamic>> services;
  final String? host;
  final String? mac;
  final String api;
  final String wsapi;
  bool isConnected = false;

  String? token;
  Response? info;
  IOWebSocketChannel? ws;
  Timer? timer;

  SmartTV({
    this.host,
    this.mac,
  })  : api = "http://$host:8001/api/v2/",
        wsapi = "wss://$host:8002/api/v2/",
        services = [];

  addService(service) {
    services.add(service);
  }

  connect({appName = 'DartSamsungSmartTVDriver'}) async {
    var completer = Completer();

    if (isConnected) {
      return;
    }

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
        throw ('Could not parse TV response $message');
      }

      if (data["data"] != null && data["data"]["token"] != null) {
        token = data["data"]["token"];
      }

      if (data["event"] != 'ms.channel.connect') {
        log('TV responded with $data');
      } else {
        log('Connection successfully established');
        isConnected = true;
      }
      completer.complete();
    });

    return completer.future;
  }

  Future<http.Response> getDeviceInfo() async {
    log("Getting device info from $api");
    return http.get(Uri.parse(api));
  }

  disconnect() {
    ws?.sink.close();
  }

  sendKey(KeyCodes key) async {
    if (!isConnected) {
      throw ('Not connected to device. Call `tv.connect()` first!');
    }

    log("Send key command  ${key.toString().split('.').last}");
    final data = json.encode({
      "method": 'ms.remote.control',
      "params": {
        "Cmd": 'Click',
        "DataOfCmd": key.toString().split('.').last,
        "Option": false,
        "TypeOfRemote": 'SendRemoteKey',
      }
    });

    ws?.sink.add(data);

    Timer(const Duration(seconds: kConnectionTimeout), () {
      throw ('Unable to connect to TV: timeout');
    });

    return Future.delayed(const Duration(milliseconds: kKeyDelay));
  }

  static discover() async {
    var completer = Completer();
    final List<SmartTV> tvs = [];

    final client = DeviceDiscoverer();
    await client.start(ipv6: false);

    client.quickDiscoverClients().listen((client) async {
      RegExp re = RegExp(r'^.*?Samsung.+UPnP.+SDK\/1\.0$');

      if (!re.hasMatch(client.server!)) {
        log("Ignoring ${client.server}");
        return;
      }
      try {
        final device = await client.getDevice();
        Uri locaion = Uri.parse(client.location!);
        final deviceExists = tvs.firstWhere((tv) => tv.host == locaion.host,
            orElse: () => SmartTV(host: null));
        if (deviceExists.host == null) {
          log("Found ${device?.friendlyName} on IP ${locaion.host}");
          final tv = SmartTV(host: locaion.host);
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
      if (tvs.isEmpty) {
        completer.completeError(
            "No Samsung TVs found. Make sure the UPNP protocol is enabled in your network.");
      } else {
        completer.complete(tvs.first);
      }
    });

    return completer.future;
  }
}
