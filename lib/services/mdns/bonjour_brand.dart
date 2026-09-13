import 'package:remote/core/models/tv_brand.dart';

/// Works out which supported brand a Bonjour service belongs to.
///
/// Brand-specific service types (`_samsungmsf._tcp`, `_lg-mrt._tcp`) carry
/// the answer in [typeBrand]. Generic types such as AirPlay and Cast are
/// advertised by many devices, so for those the TXT record has to name the
/// manufacturer (`manufacturer=LG Electronics`, `md=Samsung ...`); anything
/// else is not a TV we can drive and returns `null`.
TvBrand? bonjourBrandFor({
  required TvBrand? typeBrand,
  required Map<String, String> attributes,
}) {
  if (typeBrand != null) return typeBrand;
  final haystack = [
    attributes['manufacturer'],
    attributes['model'],
    attributes['md'],
    attributes['fn'],
  ].whereType<String>().join(' ').toLowerCase();
  if (haystack.contains('samsung')) return TvBrand.samsung;
  if (haystack.contains('lg electronics') ||
      haystack.contains('webos') ||
      RegExp(r'\blg\b').hasMatch(haystack)) {
    return TvBrand.lg;
  }
  return null;
}

/// Model name from TXT attributes, when advertised.
String? bonjourModelFor(Map<String, String> attributes) =>
    attributes['model'] ?? attributes['md'];
