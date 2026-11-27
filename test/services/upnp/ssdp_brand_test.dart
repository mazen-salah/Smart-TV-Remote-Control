import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/services/upnp/ssdp_brand.dart';

void main() {
  group('ssdpBrandFor', () {
    test('recognises the Samsung UPnP server header', () {
      expect(
        ssdpBrandFor(
          server: 'Linux/9.0 UPnP/1.0 Samsung UPnP SDK/1.0',
          st: 'urn:samsung.com:device:RemoteControlReceiver:1',
        ),
        TvBrand.samsung,
      );
    });

    test('recognises LG webOS second-screen responders', () {
      expect(
        ssdpBrandFor(
          server: 'WebOS/4.0 UPnP/1.0',
          st: 'urn:lge-com:service:webos-second-screen:1',
          usn: 'uuid:1234::urn:lge-com:service:webos-second-screen:1',
        ),
        TvBrand.lg,
      );
    });

    test('recognises Roku ECP responders', () {
      expect(
        ssdpBrandFor(
          server: 'Roku/9.4 UPnP/1.0 Roku/9.4',
          st: 'roku:ecp',
          usn: 'uuid:roku:ecp:P0A070000007',
        ),
        TvBrand.roku,
      );
      expect(ssdpBrandFor(st: 'roku:ecp'), TvBrand.roku);
    });

    test('recognises Bravia ScalarWebAPI responders', () {
      expect(
        ssdpBrandFor(
          server: 'Linux/4.9 UPnP/1.0 Sony-Bravia/1.0',
          st: 'urn:schemas-sony-com:service:ScalarWebAPI:1',
          usn:
              'uuid:00000000-0000-1010-8000-104FA8F9A04C::urn:schemas-sony-com:service:ScalarWebAPI:1',
        ),
        TvBrand.sony,
      );
    });

    test('drops routers and printers', () {
      expect(
        ssdpBrandFor(
          server: 'Linux/3.10 UPnP/1.0 MiniUPnPd/2.0',
          st: 'urn:schemas-upnp-org:device:InternetGatewayDevice:1',
        ),
        isNull,
      );
      expect(ssdpBrandFor(), isNull);
    });
  });
}
