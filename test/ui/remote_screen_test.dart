import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/remote_control/remote_screen.dart';
import 'package:remote/ui/widgets/remote_controls/components/components.dart';

class _MockTvRepository extends Mock implements TvRepository {}

class _FakeTvDevice extends Fake implements TVDevice {}

void main() {
  late _MockTvRepository repository;

  final lg = TVDevice(
    host: '10.0.0.5',
    mac: 'AA:BB:CC',
    deviceName: 'Living Room',
    manufacturer: 'LG',
  );
  final samsung = TVDevice(
    host: '10.0.0.6',
    mac: 'AA:BB:DD',
    deviceName: 'Bedroom',
    manufacturer: 'Samsung',
  );

  setUpAll(() {
    registerFallbackValue(_FakeTvDevice());
  });

  setUp(() {
    repository = _MockTvRepository();
    when(
      () => repository.connect(
        any(),
        onDisconnected: any(named: 'onDisconnected'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.disconnect()).thenAnswer((_) async {});
    when(
      () => repository.pointerMove(
        dx: any(named: 'dx'),
        dy: any(named: 'dy'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.pointerClick()).thenAnswer((_) async {});
    when(() => repository.current).thenReturn(null);
  });

  Future<void> pumpRemote(WidgetTester tester, TVDevice device) async {
    // A phone in portrait: the remote is a tall column of controls.
    tester.view.physicalSize = const Size(1200, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bloc = TvConnectionBloc(repository: repository);
    addTearDown(bloc.close);
    bloc.add(TvConnectRequested(device));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: bloc, child: const RemoteScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers the touchpad on a webOS set', (tester) async {
    await pumpRemote(tester, lg);

    expect(find.byIcon(Icons.touch_app), findsOneWidget);
    expect(find.byType(Touchpad), findsNothing);

    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pumpAndSettle();

    expect(find.byType(Touchpad), findsOneWidget);
    expect(find.byType(DirectionKeys), findsNothing);
  });

  testWidgets('switching to the keypad puts the touchpad away', (tester) async {
    await pumpRemote(tester, lg);

    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.dialpad));
    await tester.pumpAndSettle();

    expect(find.byType(NumPad), findsOneWidget);
    expect(find.byType(Touchpad), findsNothing);
  });

  testWidgets('a Tizen set gets no touchpad button', (tester) async {
    await pumpRemote(tester, samsung);

    expect(find.byIcon(Icons.touch_app), findsNothing);
    expect(find.byType(DirectionKeys), findsOneWidget);
  });
}
