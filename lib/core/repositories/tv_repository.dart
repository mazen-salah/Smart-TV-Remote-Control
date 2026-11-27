import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/services/known_tvs_storage.dart';
import 'package:remote/core/services/tv_token_storage.dart';
import 'package:remote/core/services/wake_on_lan_service.dart';
import 'package:remote/implementations/lg_tv.dart';
import 'package:remote/implementations/roku_tv.dart';
import 'package:remote/implementations/samsung_tv.dart';
import 'package:remote/implementations/sony_tv.dart';
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
  }) : _tokenStorage = tokenStorage,
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

  /// What is kept for a TV under its identifier: the pairing token, the
  /// pinned certificate (LG) and the pre-shared key (Sony). They share the
  /// identifier and its prefixes, so they move together.
  static const List<String> _credentialPrefixes = ['', 'cert:', 'psk:'];

  TVInterface? _current;
  TVDevice? _currentDevice;

  TVInterface? get current => _current;
  TVDevice? get currentDevice => _currentDevice;

  /// Runs SSDP and Bonjour sweeps in parallel and merges the results by
  /// host, so a set seen by both shows up once with the richer record.
  Future<List<TVDevice>> discoverAll() async {
    final results = await Future.wait<List<TVDevice>>([
      _sweep('SSDP', _ssdp.discoverAll),
      _sweep('Bonjour', _bonjour.discoverAll),
    ]);
    return TVDevice.mergeByHost([for (final list in results) ...list]);
  }

  /// One discovery sweep; a failure costs its results, never the scan.
  Future<List<TVDevice>> _sweep(
    String name,
    Future<List<TVDevice>> Function() run,
  ) async {
    try {
      return await run();
    } catch (e) {
      log('$name discovery failed: $e');
      return const [];
    }
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
    final tokenKey = identifier != null
        ? _tokenKeyFor(brand, identifier)
        : null;
    final savedToken = tokenKey != null ? _tokenStorage.load(tokenKey) : null;
    void onDisconnect(DisconnectionType type) => onDisconnected?.call(type);

    final TVInterface tv;
    // A Sony key is only worth keeping once the set has accepted it: a typo
    // must not overwrite the key that used to work.
    String? acceptedPskKey;
    String? acceptedPsk;
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
          pinnedCertificateSha256: certKey != null
              ? _tokenStorage.load(certKey)
              : null,
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
      case TvBrand.sony:
        final host = device.host;
        if (host == null || host.isEmpty) {
          throw ArgumentError('Sony TVs need an IP address to connect');
        }
        // The pre-shared key comes from the add-by-IP dialog; it is stored
        // like the other brands' credentials once it has worked.
        final pskKey = tokenKey != null ? 'psk:$tokenKey' : null;
        final psk =
            device.additionalInfo['sonyPsk'] as String? ??
            (pskKey != null ? _tokenStorage.load(pskKey) : null);
        final sony = SonyTV(
          host: host,
          mac: device.mac,
          deviceName: device.deviceName,
          modelName: device.modelName,
          preSharedKey: psk,
        )..setOnDisconnectedCallback(onDisconnect);
        if (pskKey != null && psk != null && psk.isNotEmpty) {
          acceptedPskKey = pskKey;
          acceptedPsk = psk;
        }
        tv = sony;
      case TvBrand.roku:
        final host = device.host;
        if (host == null || host.isEmpty) {
          throw ArgumentError('Roku devices need an IP address to connect');
        }
        // ECP needs no pairing: there is nothing to store or send back.
        tv = RokuTV(
          host: host,
          mac: device.mac,
          deviceName: device.deviceName,
          modelName: device.modelName,
        )..setOnDisconnectedCallback(onDisconnect);
    }

    await tv.connect();

    if (acceptedPskKey != null) {
      await _tokenStorage.save(acceptedPskKey, acceptedPsk!);
    }

    // The HTTP info response may have surfaced a MAC the user didn't have.
    final resolved = device.copyWith(
      mac: tv.mac ?? device.mac,
      manufacturer: device.manufacturer ?? brand.manufacturer,
    );

    // The device is keyed by MAC once one is known. If we paired under the
    // host-only key, carry its credentials over so the next connect does not
    // prompt again.
    final resolvedIdentifier = _identifierFor(resolved);
    if (identifier != null &&
        resolvedIdentifier != null &&
        resolvedIdentifier != identifier) {
      await carryCredentials(brand, identifier, resolvedIdentifier);
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
        m.contains('timeout') ||
        m.contains('timed out') ||
        m.contains('unreachable') ||
        m.contains('no route to host');
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

  /// Drops everything remembered about [device]: pairing token or client
  /// key, pinned certificate, and the known-TV entry. If it is the active
  /// connection, that is closed too.
  Future<void> forget(TVDevice device) async {
    // Credentials may have been saved under the host before the MAC was
    // known, so clear every alias, not just the preferred identifier.
    final aliases = {
      device.mac,
      device.host,
    }.whereType<String>().where((id) => id.isNotEmpty);
    for (final identifier in aliases) {
      for (final brand in TvBrand.values) {
        final key = _tokenKeyFor(brand, identifier);
        // Roku stores nothing, so there is nothing to clear for it.
        if (key == null) continue;
        for (final prefix in _credentialPrefixes) {
          await _tokenStorage.clear('$prefix$key');
        }
      }
    }
    await _knownTvsStorage.remove(device);
    final last = _knownTvsStorage.loadLastUsed();
    if (last != null && last.host == device.host) {
      await _knownTvsStorage.clearLastUsed();
    }
    if (_currentDevice != null && _currentDevice!.host == device.host) {
      await disconnect();
    }
  }

  Future<void> forgetCurrent() async {
    final device = _currentDevice;
    if (device != null) {
      await forget(device);
    }
    await disconnect();
    await _knownTvsStorage.clearLastUsed();
  }

  List<TVDevice> knownTvs() => _knownTvsStorage.loadAll();
  TVDevice? lastUsed() => _knownTvsStorage.loadLastUsed();

  /// Samsung tokens keep the bare identifier so existing installs keep
  /// their pairing; other brands are namespaced. Roku has no credentials to
  /// store at all, so it has no key either.
  String? _tokenKeyFor(TvBrand brand, String identifier) => switch (brand) {
    TvBrand.samsung => identifier,
    TvBrand.lg => 'lg:$identifier',
    TvBrand.roku => null,
    TvBrand.sony => 'sony:$identifier',
  };

  /// Moves everything stored for a TV from the identifier it was paired under
  /// to the one it is known by now — a host-only entry gains a MAC as soon as
  /// the TV answers, and the credentials have to move with it.
  @visibleForTesting
  Future<void> carryCredentials(TvBrand brand, String from, String to) async {
    final oldKey = _tokenKeyFor(brand, from);
    final newKey = _tokenKeyFor(brand, to);
    if (oldKey == null || newKey == null || oldKey == newKey) return;
    for (final prefix in _credentialPrefixes) {
      final value = _tokenStorage.load('$prefix$oldKey');
      if (value == null || value.isEmpty) continue;
      await _tokenStorage.save('$prefix$newKey', value);
    }
  }

  String? _identifierFor(TVDevice device) {
    final mac = device.mac;
    if (mac != null && mac.isNotEmpty) return mac;
    final host = device.host;
    if (host != null && host.isNotEmpty) return host;
    return null;
  }
}
