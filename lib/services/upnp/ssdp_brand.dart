import 'package:remote/core/models/tv_brand.dart';

final RegExp _samsungServer = RegExp(
  'Samsung.+UPnP.+SDK',
  caseSensitive: false,
);

/// Roku devices answer `M-SEARCH` for `roku:ecp` and name themselves in the
/// server header, e.g. `Roku/9.4 UPnP/1.0 Roku/9.4`.
final RegExp _rokuServer = RegExp('Roku', caseSensitive: false);

/// Bravia sets answer for Sony's ScalarWebAPI service.
final RegExp _sonyIds = RegExp(
  'schemas-sony-com|scalarwebapi',
  caseSensitive: false,
);

/// Classifies an SSDP responder from its headers, before fetching the device
/// description, so printers and routers are skipped without an HTTP round
/// trip. Returns `null` for anything that is not a supported TV.
TvBrand? ssdpBrandFor({String? server, String? st, String? usn}) {
  final server0 = server ?? '';
  final ids = '${st ?? ''} ${usn ?? ''} $server0'.toLowerCase();
  if (_samsungServer.hasMatch(server0) || ids.contains('samsung')) {
    return TvBrand.samsung;
  }
  if (ids.contains('lge-com') ||
      ids.contains('webos') ||
      ids.contains('lg electronics')) {
    return TvBrand.lg;
  }
  if (ids.contains('roku:ecp') || _rokuServer.hasMatch(server0)) {
    return TvBrand.roku;
  }
  if (_sonyIds.hasMatch(ids)) {
    return TvBrand.sony;
  }
  return null;
}
