import 'dart:async';
import 'dart:developer';

import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/services/multicast_lock.dart';
import 'package:remote/services/upnp/ssdp_brand.dart';
import 'package:upnp2/upnp.dart';

/// Finds Samsung and LG TVs with one SSDP `M-SEARCH` sweep.
///
/// Samsung sets answer with a `Samsung ... UPnP SDK` server header; LG sets
/// answer for `urn:lge-com:service:webos-second-screen:1`. Responders that
/// match neither are dropped before their description XML is fetched.
///
/// Android drops multicast replies unless a MulticastLock is held, so the
/// sweep runs inside [MulticastLock.acquire]/[MulticastLock.release]. On iOS
/// the UDP socket fails without Apple's multicast entitlement; that is logged
/// and Bonjour discovery covers the gap.
class SsdpDiscoveryService {
  SsdpDiscoveryService({required MulticastLock multicastLock})
    : _lock = multicastLock;

  final MulticastLock _lock;

  /// Upper bound on one device-description fetch.
  static const Duration _descriptionTimeout = Duration(seconds: 3);

  Future<List<TVDevice>> discoverAll({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final found = <String, TVDevice>{};
    await _lock.acquire();
    try {
      // Hard ceiling: whatever happens inside, discovery returns. Partial
      // results collected so far are kept.
      await _sweep(
        timeout,
        found,
      ).timeout(timeout + _descriptionTimeout + const Duration(seconds: 3));
    } on TimeoutException {
      log('SSDP: sweep exceeded its ceiling; returning ${found.length}');
    } catch (e) {
      log('SSDP unavailable: $e');
    } finally {
      await _lock.release();
    }
    return found.values.toList(growable: false);
  }

  Future<void> _sweep(Duration timeout, Map<String, TVDevice> found) async {
    final discoverer = DeviceDiscoverer();
    final candidates = <_Candidate>[];
    try {
      await discoverer.start(ipv6: false);
      final clients = discoverer
          .quickDiscoverClients(timeout: timeout)
          .timeout(timeout + const Duration(seconds: 2));
      // No awaits in this loop: awaiting inside `await for` pauses the
      // stream and with it the timeout above.
      await for (final client in clients) {
        final brand = ssdpBrandFor(
          server: client.server,
          st: client.st,
          usn: client.usn,
        );
        if (brand == null) continue;
        final host = Uri.tryParse(client.location ?? '')?.host;
        if (host == null || host.isEmpty) continue;
        if (candidates.any((c) => c.host == host)) continue;
        candidates.add(_Candidate(host: host, brand: brand, client: client));
      }
    } on TimeoutException {
      // Sweep window closed; describe what answered.
    } finally {
      try {
        discoverer.stop();
      } catch (_) {
        // Already stopped by the discoverer's own timeout.
      }
    }

    await Future.wait(
      candidates.map((candidate) async {
        Device? device;
        try {
          device = await candidate.client.getDevice().timeout(
            _descriptionTimeout,
          );
        } catch (e) {
          log('SSDP: description for ${candidate.host} unavailable: $e');
        }
        log(
          'SSDP: found ${device?.friendlyName ?? candidate.host} '
          '(${candidate.brand.name})',
        );
        found[candidate.host] = TVDevice(
          host: candidate.host,
          deviceName: device?.friendlyName,
          modelName: device?.modelName,
          manufacturer: candidate.brand.manufacturer,
        );
      }),
    );
  }
}

class _Candidate {
  const _Candidate({
    required this.host,
    required this.brand,
    required this.client,
  });
  final String host;
  final TvBrand brand;
  final DiscoveredClient client;
}
