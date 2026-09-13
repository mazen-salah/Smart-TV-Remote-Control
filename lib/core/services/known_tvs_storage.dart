import 'dart:convert';

import 'package:remote/core/models/tv_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers TVs the user has previously paired with, so the app can
/// show them instantly on launch even before discovery completes.
class KnownTvsStorage {
  KnownTvsStorage(this._prefs);

  static const String _knownTvsKey = 'known_tvs';
  static const String _lastTvKey = 'last_used_tv';

  final SharedPreferences _prefs;

  List<TVDevice> loadAll() {
    final raw = _prefs.getString(_knownTvsKey);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> save(TVDevice device) async {
    if (device.host == null) return;
    final existing = loadAll();
    final filtered = existing
        .where((d) => d.host != device.host || d.mac != device.mac)
        .toList()
      ..add(device);
    final payload = json.encode(filtered.map(_toJson).toList());
    await _prefs.setString(_knownTvsKey, payload);
  }

  Future<void> remove(TVDevice device) async {
    final filtered = loadAll()
        .where((d) => d.host != device.host || d.mac != device.mac)
        .toList();
    final payload = json.encode(filtered.map(_toJson).toList());
    await _prefs.setString(_knownTvsKey, payload);
  }

  TVDevice? loadLastUsed() {
    final raw = _prefs.getString(_lastTvKey);
    if (raw == null) return null;
    try {
      return _fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastUsed(TVDevice device) async {
    if (device.host == null) return;
    await _prefs.setString(_lastTvKey, json.encode(_toJson(device)));
  }

  Future<void> clearLastUsed() => _prefs.remove(_lastTvKey);

  Map<String, dynamic> _toJson(TVDevice d) => <String, dynamic>{
        'host': d.host,
        'mac': d.mac,
        'deviceName': d.deviceName,
        'modelName': d.modelName,
        'manufacturer': d.manufacturer,
        'serialNumber': d.serialNumber,
      };

  TVDevice _fromJson(Map<String, dynamic> m) => TVDevice(
        host: m['host'] as String?,
        mac: m['mac'] as String?,
        deviceName: m['deviceName'] as String?,
        modelName: m['modelName'] as String?,
        manufacturer: m['manufacturer'] as String?,
        serialNumber: m['serialNumber'] as String?,
      );
}
