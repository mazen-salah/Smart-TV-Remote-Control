import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/widgets/device_list_item.dart';

void main() {
  Future<void> pumpItem(WidgetTester tester, TVDevice device) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DeviceListItem(device: device, onTap: () {}),
          ),
        ),
      );

  group('DeviceListItem', () {
    testWidgets('shows the name, address and brand', (tester) async {
      await pumpItem(
        tester,
        TVDevice(
          host: '10.0.0.5',
          mac: 'AA:BB:CC:DD:EE:FF',
          deviceName: 'Living Room',
          manufacturer: 'Samsung',
        ),
      );

      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('IP: 10.0.0.5'), findsOneWidget);
      expect(find.text('MAC: AA:BB:CC:DD:EE:FF'), findsOneWidget);
      expect(find.text('Samsung'), findsOneWidget);
    });

    testWidgets('labels an LG set from its manufacturer', (tester) async {
      await pumpItem(
        tester,
        TVDevice(host: '10.0.0.9', manufacturer: 'LG Electronics'),
      );

      expect(find.text('LG'), findsOneWidget);
    });

    testWidgets('falls back to the brand the repository would pick', (
      tester,
    ) async {
      // `TvBrand.fromDevice` defaults to Samsung, so the chip shows what a tap
      // will actually use rather than nothing.
      await pumpItem(tester, TVDevice(host: '10.0.0.7'));

      expect(find.text('Samsung'), findsOneWidget);
    });

    testWidgets('a long name does not squeeze the brand out', (tester) async {
      await pumpItem(
        tester,
        TVDevice(
          host: '10.0.0.8',
          deviceName:
              'A very long television name that would otherwise '
              'push everything else off the card',
          manufacturer: 'Samsung',
        ),
      );

      expect(find.text('Samsung'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
