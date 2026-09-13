import 'dart:async';
import 'dart:developer';

import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/services/known_tvs_storage.dart';
import 'package:remote/core/services/tv_token_storage.dart';
import 'package:remote/core/services/wake_on_lan_service.dart';
import 'package:remote/implementations/lg_tv.dart';
import 'package:remote/implementations/samsung_tv.dart';
import 'package:remote/services/mdns/bonjour_discovery_service.dart';
import 'package:remote/services/upnp/ssdp_discovery_service.dart';

/// Single coordinator for discovery, connect, send-key, and disconnect.
///
/// The UI talks to a `TvConnectionBloc`; that bloc talks to this repository.
/// Brand specifics (Samsung WSS v2, LG WebOS) live in `lib/implementations/`;
/// the brand is picked per device with [TvBrand.fromDevice].
class TvRepository {
  TvRepository({
    required TvTokenStorage tokenStorage,
    required KnownTvsStorage knownTvsStorage,
    required WakeOnLanService wakeOnLanService,
    required SsdpDiscoveryService ssdpDiscoveryService,
    required BonjourDiscoveryService bonjourDiscoveryService,
  })  : _tokenStorage = tokenStorage,
        _knownTvsStorage = knownTvsStorage,
        _wol = wakeOnLanService,
        _ssdp = ssdpDiscoveryService,
        _bonjour = bonjourDiscoveryService;

  static const Duration _wakeRetryDelay = Duration(seconds: 6);

  final TvTokenStorage _tokenStorage;
  final KnownTvsStorage _knownTvsStorage;
  final WakeOnLanService _wol;
  final SsdpDiscoveryService _ssdp;
  final BonjourDiscoveryService _bonjour;

  TVInterface? _current;
  TVDevice? _currentDevice;

  TVInterface? get current => _current;
  TVDevice? get currentDevice => _currentDevice;

  /// Runs SSDP and Bonjour sweeps in parallel and merges the results,
  /// de-duplicated by host and MAC via [TVDevice.==].
  Future<List<TVDevice>> discoverAll() async {
    final results = await Future.wait<List<TVDevice>>([
      _ssdp.discoverAll().catchError((Object _) => <TVDevice>[]),
      _bonjour.discoverAll().catchError((Object _) => <TVDevice>[]),
    ]);
    return <TVDevice>{for (final list in results) ...list}.toList();
  }

  /// Connect to [device]. If the TV refuses the connection and we have
  /// its MAC, send a WoL magic packet and retry once.
  Future<void> connect(
    TVDevice device, {
    void Function(DisconnectionType)? onDisconnected,
  }) async {
    await disconnect();

    try {
      await _doConnect(device, onDisconnected: onDisconnected);
    } catch (e) {
      if (_isRefusedError(e) && device.mac != null) {
        log('Connect refused, attempting WoL for ${device.mac}');
        final waked = await _wol.wake(mac: device.mac!);
        if (waked) {
          await Future<void>.delayed(_wakeRetryDelay);
          await _doConnect(device, onDisconnected: onDisconnected);
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> _doConnect(
    TVDevice device, {
    void Function(DisconnectionType)? onDisconnected,
  }) async {
    final brand = TvBrand.fromDevice(device);
    final identifier = _identifierFor(device);
    final tokenKey =
        identifier != null ? _tokenKeyFor(brand, identifier) : null;
    final savedToken = tokenKey != null ? _tokenStorage.load(tokenKey) : null;
    void onDisconnect(DisconnectionType type) => onDisconnected?.call(type);

    final TVInterface tv;
    switch (brand) {
      case TvBrand.samsung:
        final samsung = SamsungTV(
          host: device.host,
          mac: device.mac,
          deviceName: device.deviceName,
          modelName: device.modelName,
          token: savedToken,
        )..setOnDisconnectedCallback(onDisconnect);
        if (tokenKey != null) {
          samsung.setOnTokenReceivedCallback((token) {
            unawaited(_tokenStorage.save(tokenKey, token));
          });
        }
        tv = samsung;
      case TvBrand.lg:
        final host = device.host;
        if (host == null || host.isEmpty) {
          throw ArgumentError('LG TVs need an IP address to connect');
        }
        final certKey = tokenKey != null ? 'cert:$tokenKey' : null;
        final lg = LGTV(
          host: host,
          mac: device.mac,
          deviceName: device.deviceName,
          modelName: device.modelName,
          clientKey: savedToken,
          pinnedCertificateSha256:
              certKey != null ? _tokenStorage.load(certKey) : null,
        )..setOnDisconnectedCallback(onDisconnect);
        if (tokenKey != null) {
          lg.setOnClientKeyReceivedCallback((key) {
            unawaited(_tokenStorage.save(tokenKey, key));
          });
        }
        if (certKey != null) {
          lg.setOnCertificatePinnedCallback((fingerprint) {
            unawaited(_tokenStorage.save(certKey, fingerprint));
          });
        }
        tv = lg;
    }

    await tv.connect();

    // The HTTP info response may have surfaced a MAC the user didn't have.
    final resolved = device.copyWith(
      mac: tv.mac ?? device.mac,
      manufacturer: device.manufacturer ?? brand.manufacturer,
    );

    // The device is keyed by MAC once one is known. If we paired under the
    // host-only key, carry the token over so the next connect doesn't prompt.
    final resolvedIdentifier = _identifierFor(resolved);
    if (tokenKey != null &&
        resolvedIdentifier != null &&
        resolvedIdentifier != identifier) {
      final token = _tokenStorage.load(tokenKey);
      if (token != null) {
        await _tokenStorage.save(
          _tokenKeyFor(brand, resolvedIdentifier),
          token,
        );
      }
    }

    _current = tv;
    _currentDevice = resolved;
    await _knownTvsStorage.save(resolved);
    await _knownTvsStorage.saveLastUsed(resolved);
  }

  bool _isRefusedError(Object error) {
    final m = error.toString().toLowerCase();
    return m.contains('connection refused') ||
        m.contains('errno = 111') ||
        m.contains('failed host lookup') ||
        m.contains('connection timeout');
  }

  Future<void> sendKey(KeyCodes key) async {
    final tv = _current;
    if (tv == null) {
      throw StateError('No active TV connection');
    }
    await tv.sendKey(key);
  }

  Future<void> disconnect() async {
    _current?.disconnect();
    _current = null;
    _currentDevice = null;
  }

  Future<void> forgetCurrent() async {
    final device = _currentDevice;
    if (device != null) {
      final identifier = _identifierFor(device);
      if (identifier != null) {
        for (final brand in TvBrand.values) {
          final key = _tokenKeyFor(brand, identifier);
          await _tokenStorage.clear(key);
          await _tokenStorage.clear('cert:$key');
        }
      }
      await _knownTvsStorage.remove(device);
    }
    await disconnect();
    await _knownTvsStorage.clearLastUsed();
  }

  List<TVDevice> knownTvs() => _knownTvsStorage.loadAll();
  TVDevice? lastUsed() => _knownTvsStorage.loadLastUsed();

  /// Samsung tokens keep the bare identifier so existing installs keep
  /// their pairing; other brands are namespaced.
  String _tokenKeyFor(TvBrand brand, String identifier) => switch (brand) {
        TvBrand.samsung => identifier,
        TvBrand.lg => 'lg:$identifier',
      };

  String? _identifierFor(TVDevice device) {
    final mac = device.mac;
    if (mac != null && mac.isNotEmpty) return mac;
    final host = device.host;
    if (host != null && host.isNotEmpty) return host;
    return null;
  }
}
