import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/widgets/manual_ip_dialog.dart';

void main() {
  ManualIpResult? result;

  Future<void> openDialog(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async =>
                    result = await ManualIpDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('refuses an empty address', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an IP address'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('refuses something that is not an IPv4 address', (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField).first, '192.168.1');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid IPv4 address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '192.168.1.999');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid IPv4 address'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('returns the address, name and Samsung by default', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField).first, '192.168.1.42');
    await tester.enterText(find.byType(TextFormField).last, 'Living Room');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result?.host, '192.168.1.42');
    expect(result?.name, 'Living Room');
    expect(result?.brand, TvBrand.samsung);
  });

  testWidgets('carries the LG brand when it is selected', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('LG'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '192.168.1.57');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result?.brand, TvBrand.lg);
    expect(result?.name, isNull);
  });
}
