import 'dart:async';
import 'dart:io';

/// A stand-in Roku device speaking ECP over plain HTTP.
///
/// Answers `GET /query/device-info` with [deviceInfo] and every `POST`
/// (keypress, launch) with the status in [postStatus], recording the paths it
/// was asked for so tests can assert what the app sent.
class FakeRoku {
  FakeRoku._(this._server);

  static Future<FakeRoku> start({
    String? deviceInfo,
    int postStatus = 200,
    Duration? delay,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final roku = FakeRoku._(server)
      ..deviceInfo = deviceInfo ?? defaultDeviceInfo
      ..postStatus = postStatus
      ..delay = delay;
    unawaited(roku._serve());
    return roku;
  }

  static const String defaultDeviceInfo = '''
<?xml version="1.0" encoding="UTF-8"?>
<device-info>
  <udn>044c8af6-1111-2222-3333-444455556666</udn>
  <serial-number>X0123456789AB</serial-number>
  <device-id>ABC123</device-id>
  <model-name>Roku Ultra</model-name>
  <model-number>4800X</model-number>
  <user-device-name>Living Room TV</user-device-name>
  <friendly-device-name>Roku Ultra - Living Room</friendly-device-name>
  <wifi-mac>d0:4d:2c:00:11:22</wifi-mac>
  <power-mode>PowerOn</power-mode>
</device-info>
''';

  final HttpServer _server;

  late String deviceInfo;
  late int postStatus;

  /// Artificial latency, to exercise timeouts.
  Duration? delay;

  /// Every request path the device was asked for, in order.
  final List<String> requests = [];

  int get port => _server.port;
  String get host => _server.address.address;

  Future<void> _serve() async {
    await for (final request in _server) {
      requests.add(request.uri.path);
      if (delay != null) await Future<void>.delayed(delay!);
      if (request.method == 'POST') {
        request.response.statusCode = postStatus;
        await request.response.close();
        continue;
      }
      if (request.uri.path == '/query/device-info') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType('text', 'xml', charset: 'utf-8')
          ..write(deviceInfo);
        await request.response.close();
        continue;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }

  Future<void> close() => _server.close(force: true);
}
