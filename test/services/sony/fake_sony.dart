import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A stand-in Bravia: JSON-RPC on `/sony/system` and the SOAP IRCC endpoint on
/// `/sony/IRCC`.
///
/// With [preSharedKey] set it answers 403 to any request that does not carry a
/// matching `X-Auth-PSK`, which is how a real set with IP control configured
/// behaves. Everything it was asked for is recorded for assertions.
class FakeSony {
  FakeSony._(this._server);

  static Future<FakeSony> start({String? preSharedKey}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sony = FakeSony._(server)..preSharedKey = preSharedKey;
    unawaited(sony._serve());
    return sony;
  }

  final HttpServer _server;

  /// When set, requests without a matching `X-Auth-PSK` get a 403.
  String? preSharedKey;

  /// Button name → code, as `getRemoteControllerInfo` reports it. Empty means
  /// the set does not answer that call.
  Map<String, String> remoteCodes = {};

  /// Set to fail the next `getRemoteControllerInfo` with this status.
  int remoteCodesStatus = 200;

  /// Everything the set received, newest last.
  final List<SonyRequest> requests = [];

  int get port => _server.port;
  String get host => _server.address.address;

  Future<void> _serve() async {
    await for (final request in _server) {
      final body = await utf8.decoder.bind(request).join();
      final auth = request.headers.value('x-auth-psk');
      requests.add(
        SonyRequest(
          path: request.uri.path,
          body: body,
          auth: auth,
          soapAction: request.headers.value('soapaction'),
        ),
      );

      if (request.uri.path == '/sony/IRCC') {
        request.response.statusCode = _authorised(auth) ? 200 : 403;
        request.response.write('<ok/>');
        await request.response.close();
        continue;
      }

      if (request.uri.path == '/sony/system' && _authorised(auth)) {
        final message = jsonDecode(body) as Map<String, dynamic>;
        final method = message['method'] as String;
        request.response.headers.contentType = ContentType.json;
        switch (method) {
          case 'getRemoteControllerInfo':
            request.response.statusCode = remoteCodesStatus;
            if (remoteCodesStatus == 200) {
              request.response.write(
                jsonEncode({
                  'result': [
                    [
                      for (final entry in remoteCodes.entries)
                        {'name': entry.key, 'value': entry.value},
                    ],
                  ],
                }),
              );
            }
          default:
            request.response.write(
              jsonEncode({
                'result': [
                  {
                    'name': 'BRAVIA',
                    'model': 'KD-55XH9096',
                    'macAddr': 'AC:9B:0A:11:22:33',
                    'serial': '1234567',
                  },
                ],
              }),
            );
        }
        await request.response.close();
        continue;
      }

      request.response.statusCode = _authorised(auth) ? 404 : 403;
      await request.response.close();
    }
  }

  bool _authorised(String? auth) {
    final expected = preSharedKey;
    if (expected == null) return true;
    return auth == expected;
  }

  Future<void> close() => _server.close(force: true);
}

class SonyRequest {
  const SonyRequest({
    required this.path,
    required this.body,
    this.auth,
    this.soapAction,
  });

  final String path;
  final String body;
  final String? auth;
  final String? soapAction;

  /// The IRCC button code inside the SOAP envelope, if this was a key press.
  String? get irccCode =>
      RegExp('<IRCCCode>([^<]+)</IRCCCode>').firstMatch(body)?.group(1);

  /// The JSON-RPC method, if this was a JSON call.
  String? get method => body.isEmpty
      ? null
      : (jsonDecode(body) as Map<String, dynamic>)['method'] as String?;
}
