import 'package:remote/core/models/tv_brand.dart';

final RegExp _samsungServer = RegExp(
  'Samsung.+UPnP.+SDK',
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
  return null;
}
