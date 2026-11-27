import 'package:remote/core/models/tv_device.dart';

/// TV brands the app has a protocol implementation for.
enum TvBrand {
  samsung('Samsung'),
  lg('LG'),
  roku('Roku'),
  sony('Sony');

  const TvBrand(this.manufacturer);

  /// Value stored in [TVDevice.manufacturer] for devices of this brand.
  final String manufacturer;

  /// Resolves the brand for [device] from its manufacturer, falling back to
  /// hints in the model name. Unknown brands default to Samsung, which is the
  /// brand most users of this app have and the only one verified on hardware.
  static TvBrand fromDevice(TVDevice device) {
    final manufacturer = (device.manufacturer ?? '').toLowerCase();
    final model = (device.modelName ?? '').toLowerCase();
    if (manufacturer.contains('lg') ||
        manufacturer.contains('webos') ||
        model.contains('webos')) {
      return TvBrand.lg;
    }
    if (manufacturer.contains('roku') || model.contains('roku')) {
      return TvBrand.roku;
    }
    if (manufacturer.contains('sony') ||
        manufacturer.contains('bravia') ||
        model.contains('bravia') ||
        model.contains('kdl-') ||
        model.contains('kd-')) {
      return TvBrand.sony;
    }
    return TvBrand.samsung;
  }
}
