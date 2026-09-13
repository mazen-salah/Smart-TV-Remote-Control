import 'dart:async';
import 'dart:developer';

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

  Future<List<TVDevice>> discoverAll({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final found = <String, TVDevice>{};
    await _lock.acquire();
    final discoverer = DeviceDiscoverer();
    try {
      await discoverer.start(ipv6: false);
      final clients = discoverer
          .quickDiscoverClients(timeout: timeout)
          .timeout(timeout + const Duration(seconds: 2));
      await for (final client in clients) {
        final brand = ssdpBrandFor(
          server: client.server,
          st: client.st,
          usn: client.usn,
        );
        if (brand == null) continue;
        final host = Uri.tryParse(client.location ?? '')?.host;
        if (host == null || host.isEmpty || found.containsKey(host)) continue;

        Device? device;
        try {
          device = await client.getDevice();
        } catch (e) {
          log('SSDP: description for $host unavailable: $e');
        }
        log('SSDP: found ${device?.friendlyName ?? host} (${brand.name})');
        found[host] = TVDevice(
          host: host,
          deviceName: device?.friendlyName,
          modelName: device?.modelName,
          manufacturer: brand.manufacturer,
        );
      }
    } on TimeoutException {
      // The sweep window closed; whatever answered is in [found].
    } catch (e) {
      log('SSDP unavailable: $e');
    } finally {
      try {
        discoverer.stop();
      } catch (_) {
        // Already stopped by the discoverer's own timeout.
      }
      await _lock.release();
    }
    return found.values.toList(growable: false);
  }
}
