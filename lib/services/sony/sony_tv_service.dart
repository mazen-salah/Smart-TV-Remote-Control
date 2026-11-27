import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/sony/sony_ircc.dart';

/// The TV refused the pre-shared key (or none is configured on either side).
class SonyAuthException implements Exception {
  const SonyAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client for Sony's BRAVIA IP control.
///
/// Two interfaces, both on port 80: a JSON-RPC API at `/sony/<service>` for
/// queries such as `system.getSystemInformation`, and an IRCC endpoint at
/// `/sony/IRCC` that takes a SOAP envelope with a base64 button code. Both are
/// gated behind *Settings → Network → Home network → IP control →
/// Authentication*, which is where the pre-shared key is set: with
/// "Normal and Pre-Shared Key" every request has to carry it in `X-Auth-PSK`.
class SonyTvService {
  SonyTvService({
    required this.host,
    this.port = 80,
    this.preSharedKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const Duration kTimeout = Duration(seconds: 5);
  static const String _irccAction =
      'urn:schemas-sony-com:service:IRCC:1#X_SendIRCC';

  final String host;
  final int port;
  final String? preSharedKey;
  final http.Client _client;

  bool _connected = false;
  String? _mac;
  String? _deviceName;
  String? _modelName;
  String? _serialNumber;

  /// Button code table as reported by the TV itself, when it answered
  /// `getRemoteControllerInfo`. Empty means "use the documented fallback".
  Map<String, String> _remoteCodes = const {};

  bool get isConnected => _connected;
  String? get mac => _mac;
  String? get deviceName => _deviceName;
  String? get modelName => _modelName;
  String? get serialNumber => _serialNumber;

  /// The names the TV reported for its own buttons; empty before connect.
  Map<String, String> get remoteCodes => _remoteCodes;

  void Function(DisconnectionType)? onDisconnected;

  Uri _jsonRpcUri(String service) =>
      Uri.parse('http://$host:$port/sony/$service');
  Uri get _irccUri => Uri.parse('http://$host:$port/sony/IRCC');

  Map<String, String> get _headers => {
    if (preSharedKey != null && preSharedKey!.isNotEmpty)
      'X-Auth-PSK': preSharedKey!,
  };

  /// Asks the TV who it is. A Bravia with a pre-shared key configured rejects
  /// everything else, so this doubles as the authentication check.
  Future<void> connect() async {
    final info = await getSystemInformation();
    _deviceName = info['name'] as String?;
    _modelName = info['model'] as String?;
    _mac = info['macAddr'] as String?;
    _serialNumber = info['serial'] as String?;
    // Best effort: a set that does not answer still accepts the documented
    // codes for the common buttons.
    _remoteCodes = await _fetchRemoteCodes();
    _connected = true;
  }

  void disconnect() {
    _connected = false;
    _remoteCodes = const {};
    _client.close();
  }

  Future<void> ensureConnection() async {
    if (!_connected) await connect();
  }

  /// `system.getSystemInformation` — name, model, MAC and serial number.
  Future<Map<String, dynamic>> getSystemInformation() async {
    final result = await jsonRpc(
      service: 'system',
      method: 'getSystemInformation',
    );
    if (result.isEmpty) {
      throw const FormatException('Sony returned no system information');
    }
    return Map<String, dynamic>.from(result.first as Map);
  }

  Future<Map<String, String>> _fetchRemoteCodes() async {
    try {
      final result = await jsonRpc(
        service: 'system',
        method: 'getRemoteControllerInfo',
      );
      if (result.isEmpty) return const {};
      // The set answers `[[{name, value}, ...]]`; older ones answer the flat
      // list, so accept either shape.
      final first = result.first;
      final codes = first is List ? first : result;
      return {
        for (final code in codes)
          if (code is Map && code['name'] != null && code['value'] != null)
            code['name'] as String: code['value'] as String,
      };
    } catch (e) {
      log('Sony does not report its remote codes: $e');
      return const {};
    }
  }

  /// One JSON-RPC call to a Sony service such as `system` or `appControl`.
  Future<List<dynamic>> jsonRpc({
    required String service,
    required String method,
    List<dynamic> params = const [],
    String version = '1.0',
  }) async {
    final uri = _jsonRpcUri(service);
    final body = jsonEncode({
      'method': method,
      'id': _nextRequestId++,
      'params': params,
      'version': version,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(kTimeout);
    } on Exception catch (e) {
      _handleTransportError(e);
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SonyAuthException(
        'The TV rejected the pre-shared key. Check IP control settings on the '
        'TV and the key entered in the app.',
      );
    }
    if (response.statusCode != 200) {
      throw HttpException(
        'Sony answered ${response.statusCode} for $method',
        uri: uri,
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw FormatException('Sony sent a reply we cannot read: $e');
    }
    if (decoded['error'] != null) {
      throw HttpException(
        'Sony refused $method: ${decoded['error']}',
        uri: uri,
      );
    }
    final result = decoded['result'];
    return result is List ? result : const [];
  }

  int _nextRequestId = 1;

  Future<void> sendKey(KeyCodes key) async {
    final code = sonyIrccCodeFor(key, remoteCodes: _remoteCodes);
    if (code == null) {
      log('Sony: no IRCC code for ${key.name}, ignored');
      return;
    }
    await sendIrcc(code);
  }

  /// Power off. A Bravia that is off does not answer on the network, so this
  /// is the one key that cannot be a toggle.
  Future<void> power() => sendIrcc(sonyIrccFallback['PowerOff']!);

  /// Sends one IRCC button code as `X_SendIRCC`.
  Future<void> sendIrcc(String code) async {
    // The envelope is fixed; only the button code changes.
    final body =
        '''
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
      <IRCCCode>$code</IRCCCode>
    </u:X_SendIRCC>
  </s:Body>
</s:Envelope>''';

    final http.Response response;
    try {
      response = await _client
          .post(
            _irccUri,
            headers: {
              ..._headers,
              'Content-Type': 'text/xml; charset=UTF-8',
              'SOAPACTION': '"$_irccAction"',
            },
            body: body,
          )
          .timeout(kTimeout);
    } on Exception catch (e) {
      _handleTransportError(e);
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SonyAuthException(
        'The TV rejected the pre-shared key. Check IP control settings on the '
        'TV and the key entered in the app.',
      );
    }
    if (response.statusCode != 200) {
      throw HttpException(
        'Sony answered ${response.statusCode} for IRCC',
        uri: _irccUri,
      );
    }
  }

  void _handleTransportError(Object error) {
    log('Sony is unreachable: $error');
    if (!_connected) return;
    _connected = false;
    onDisconnected?.call(DisconnectionType.networkError);
  }
}
