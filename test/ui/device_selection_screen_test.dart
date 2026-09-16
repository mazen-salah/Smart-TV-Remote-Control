import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/connectivity/connectivity_bloc.dart';
import 'package:remote/blocs/device_discovery/device_discovery_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/device_selection_screen.dart';
import 'package:remote/ui/theme/app_theme.dart';

class _MockTvRepository extends Mock implements TvRepository {}

class _FakeTvDevice extends Fake implements TVDevice {}

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity(this.results);
  final List<ConnectivityResult> results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTvDevice()));

  late _MockTvRepository repository;

  final livingRoom = TVDevice(
    host: '192.168.1.42',
    mac: 'AA:BB:CC',
    deviceName: 'Living Room TV',
    manufacturer: 'Samsung',
  );

  setUp(() {
    repository = _MockTvRepository();
    when(repository.knownTvs).thenReturn([]);
    when(repository.lastUsed).thenReturn(null);
    when(repository.discoverAll).thenAnswer((_) async => [livingRoom]);
    when(() => repository.forget(any())).thenAnswer((_) async {});
    when(repository.disconnect).thenAnswer((_) async {});
    when(
      () => repository.connect(
        any(),
        onDisconnected: any(named: 'onDisconnected'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPicker(
    WidgetTester tester, {
    List<ConnectivityResult> connectivity = const [ConnectivityResult.wifi],
  }) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ConnectivityCubit(
              connectivity: _FakeConnectivity(connectivity),
            ),
          ),
          BlocProvider(create: (_) => TvConnectionBloc(repository: repository)),
          BlocProvider(
            create: (_) =>
                DeviceDiscoveryBloc(repository: repository)
                  ..add(const DiscoveryStarted()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeviceSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists a discovered TV with its address', (tester) async {
    await pumpPicker(tester);

    expect(find.text('Living Room TV'), findsOneWidget);
    expect(find.text('IP: 192.168.1.42'), findsOneWidget);
  });

  testWidgets('tapping a TV asks the repository to connect', (tester) async {
    await pumpPicker(tester);

    await tester.tap(find.text('Living Room TV'));
    await tester.pump();

    verify(
      () => repository.connect(
        any(
          that: isA<TVDevice>().having((d) => d.host, 'host', '192.168.1.42'),
        ),
        onDisconnected: any(named: 'onDisconnected'),
      ),
    ).called(1);
  });

  testWidgets('long-pressing offers to forget the TV', (tester) async {
    await pumpPicker(tester);

    await tester.longPress(find.text('Living Room TV'));
    await tester.pumpAndSettle();
    expect(find.text('Forget this TV'), findsOneWidget);

    await tester.tap(find.text('Forget'));
    await tester.pumpAndSettle();

    verify(() => repository.forget(any())).called(1);
    expect(find.text('Living Room TV'), findsNothing);
  });

  testWidgets('cancelling the forget dialog keeps the TV', (tester) async {
    await pumpPicker(tester);

    await tester.longPress(find.text('Living Room TV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.forget(any()));
    expect(find.text('Living Room TV'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing answers', (tester) async {
    when(repository.discoverAll).thenAnswer((_) async => []);

    await pumpPicker(tester);

    expect(find.text('No devices found'), findsWidgets);
    expect(find.byIcon(Icons.tv_off), findsOneWidget);
  });

  testWidgets('asks for Wi-Fi instead of scanning when offline', (
    tester,
  ) async {
    await pumpPicker(tester, connectivity: const [ConnectivityResult.none]);

    expect(find.text('No Wi-Fi connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });
}
