import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/services/mdns/bonjour_brand.dart';

void main() {
  group('bonjourBrandFor', () {
    test('trusts the brand implied by a brand-specific service type', () {
      expect(
        bonjourBrandFor(typeBrand: TvBrand.samsung, attributes: const {}),
        TvBrand.samsung,
      );
    });

    test('reads the manufacturer from AirPlay TXT records', () {
      expect(
        bonjourBrandFor(
          typeBrand: null,
          attributes: const {
            'manufacturer': 'LG Electronics',
            'model': 'OLED55C3',
          },
        ),
        TvBrand.lg,
      );
      expect(
        bonjourBrandFor(
          typeBrand: null,
          attributes: const {'manufacturer': 'Samsung', 'model': 'QN65Q80C'},
        ),
        TvBrand.samsung,
      );
    });

    test('reads the model from Cast TXT records', () {
      expect(
        bonjourBrandFor(
          typeBrand: null,
          attributes: const {'md': 'LG webOS TV', 'fn': 'Living room'},
        ),
        TvBrand.lg,
      );
    });

    test('ignores generic devices that are not a supported TV', () {
      expect(
        bonjourBrandFor(
          typeBrand: null,
          attributes: const {
            'manufacturer': 'Apple Inc.',
            'model': 'AppleTV14,1',
          },
        ),
        isNull,
      );
      expect(
        bonjourBrandFor(
          typeBrand: null,
          attributes: const {'md': 'Chromecast', 'fn': 'Kitchen'},
        ),
        isNull,
      );
    });
  });
}
