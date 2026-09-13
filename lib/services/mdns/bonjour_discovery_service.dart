import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/services/mdns/bonjour_brand.dart';

/// Finds TVs through the platform's own service browser (Bonjour on Apple
/// platforms, NSD on Android) via `bonsoir`.
///
/// Using the system browser matters: raw multicast sockets need Apple's
/// restricted multicast entitlement on iOS 14+ and a MulticastLock on
/// Android, whereas the system browser needs neither. Every type listed here
/// must also appear under `NSBonjourServices` in `ios/Runner/Info.plist`.
class BonjourDiscoveryService {
  static const List<_ServiceQuery> _queries = [
    _ServiceQuery(type: '_samsungmsf._tcp', brand: TvBrand.samsung),
    _ServiceQuery(type: '_lg-mrt._tcp', brand: TvBrand.lg),
    _ServiceQuery(type: '_airplay._tcp'),
    _ServiceQuery(type: '_googlecast._tcp'),
  ];

  Future<List<TVDevice>> discoverAll({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final found = <String, TVDevice>{};
    await Future.wait(_queries.map((q) => _scan(q, timeout, found)));
    return found.values.toList(growable: false);
  }

  Future<void> _scan(
    _ServiceQuery query,
    Duration timeout,
    Map<String, TVDevice> found,
  ) async {
    BonsoirDiscovery? discovery;
    StreamSubscription<BonsoirDiscoveryEvent>? sub;
    try {
      discovery = BonsoirDiscovery(type: query.type);
      await discovery.initialize();
      final resolver = discovery.serviceResolver;
      sub = discovery.eventStream?.listen((event) {
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent(:final service):
            unawaited(service.resolve(resolver));
          case BonsoirDiscoveryServiceResolvedEvent(:final service):
            _add(query, service, found);
          default:
            break;
        }
      });
      await discovery.start();
      await Future<void>.delayed(timeout);
    } catch (e) {
      log('Bonjour ${query.type} failed: $e');
    } finally {
      await sub?.cancel();
      try {
        await discovery?.stop();
      } catch (_) {
        // Already stopped or never started.
      }
    }
  }

  void _add(
    _ServiceQuery query,
    BonsoirService service,
    Map<String, TVDevice> found,
  ) {
    final host = _firstIPv4(service.hostAddresses);
    if (host == null || found.containsKey(host)) return;
    final brand = bonjourBrandFor(
      typeBrand: query.brand,
      attributes: service.attributes,
    );
    if (brand == null) return;
    found[host] = TVDevice(
      host: host,
      deviceName: service.name,
      modelName: bonjourModelFor(service.attributes),
      manufacturer: brand.manufacturer,
    );
  }

  String? _firstIPv4(List<String> addresses) {
    for (final address in addresses) {
      final parsed = InternetAddress.tryParse(address);
      if (parsed != null && parsed.type == InternetAddressType.IPv4) {
        return parsed.address;
      }
    }
    return null;
  }
}

class _ServiceQuery {
  const _ServiceQuery({required this.type, this.brand});
  final String type;
  final TvBrand? brand;
}
