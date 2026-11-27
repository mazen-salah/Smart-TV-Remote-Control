import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';

void main() {
  group('TvBrand.fromDevice', () {
    test('resolves LG from manufacturer regardless of case', () {
      expect(TvBrand.fromDevice(TVDevice(manufacturer: 'lg')), TvBrand.lg);
      expect(
        TvBrand.fromDevice(TVDevice(manufacturer: 'LG Electronics')),
        TvBrand.lg,
      );
    });

    test('resolves LG from a webOS model hint', () {
      expect(
        TvBrand.fromDevice(TVDevice(modelName: 'OLED55C3 webOS TV')),
        TvBrand.lg,
      );
    });

    test('resolves Roku from manufacturer or model', () {
      expect(TvBrand.fromDevice(TVDevice(manufacturer: 'Roku')), TvBrand.roku);
      expect(
        TvBrand.fromDevice(TVDevice(modelName: 'Roku Streaming Stick 4K')),
        TvBrand.roku,
      );
    });

    test('resolves Sony from manufacturer or Bravia model hints', () {
      expect(TvBrand.fromDevice(TVDevice(manufacturer: 'Sony')), TvBrand.sony);
      expect(
        TvBrand.fromDevice(TVDevice(modelName: 'BRAVIA 4K GB')),
        TvBrand.sony,
      );
      expect(
        TvBrand.fromDevice(TVDevice(modelName: 'KD-55XH9096')),
        TvBrand.sony,
      );
    });

    test('resolves Samsung from manufacturer', () {
      expect(
        TvBrand.fromDevice(TVDevice(manufacturer: 'Samsung')),
        TvBrand.samsung,
      );
    });

    test('defaults to Samsung when nothing is known', () {
      expect(TvBrand.fromDevice(TVDevice(host: '10.0.0.1')), TvBrand.samsung);
      expect(
        TvBrand.fromDevice(TVDevice(manufacturer: 'Manual')),
        TvBrand.samsung,
      );
    });
  });
}
