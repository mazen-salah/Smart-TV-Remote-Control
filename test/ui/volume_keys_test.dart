import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/core/services/hardware_volume_keys.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/remote_control/remote_screen.dart';

class _MockTvRepository extends Mock implements TvRepository {}

class _FakeTvDevice extends Fake implements TVDevice {}

/// While the remote is open on a connected TV, the phone's volume rocker has to
/// reach the TV rather than the phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/screen_volume_keys');
  final platformCalls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> pressKey(String direction) => messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('onVolumeKey', direction),
    ),
    (_) {},
  );

  late _MockTvRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeTvDevice());
    registerFallbackValue(KeyCodes.KEY_VOLUP);
  });

  setUp(() {
    platformCalls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      platformCalls.add(call);
      return null;
    });
    repository = _MockTvRepository();
    when(
      () => repository.connect(
        any(),
        onDisconnected: any(named: 'onDisconnected'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.disconnect()).thenAnswer((_) async {});
    when(() => repository.sendKey(any())).thenAnswer((_) async {});
    when(() => repository.current).thenReturn(null);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<TvConnectionBloc> pumpRemote(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final bloc = TvConnectionBloc(repository: repository);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: RemoteScreen(
            volumeKeys: HardwareVolumeKeys(channel: channel, isAndroid: true),
          ),
        ),
      ),
    );
    return bloc;
  }

  testWidgets('captures the rocker once the TV is connected', (tester) async {
    final bloc = await pumpRemote(tester);
    expect(platformCalls, isEmpty, reason: 'nothing to control yet');

    bloc.add(TvConnectRequested(TVDevice(host: '10.0.0.5')));
    await tester.pumpAndSettle();

    expect(platformCalls.map((call) => call.method), ['start']);

    await pressKey('up');
    await tester.pump();
    await pressKey('down');
    await tester.pump();

    verify(() => repository.sendKey(KeyCodes.KEY_VOLUP)).called(1);
    verify(() => repository.sendKey(KeyCodes.KEY_VOLDOWN)).called(1);
  });

  testWidgets('hands the keys back when the remote is left', (tester) async {
    final bloc = await pumpRemote(tester);
    bloc.add(TvConnectRequested(TVDevice(host: '10.0.0.5')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(platformCalls.map((call) => call.method), ['start', 'stop']);
  });

  testWidgets('does not capture when the connection drops', (tester) async {
    final bloc = await pumpRemote(tester);
    bloc.add(TvConnectRequested(TVDevice(host: '10.0.0.5')));
    await tester.pumpAndSettle();

    bloc.add(const TvDisconnectionDetected('networkError'));
    await tester.pumpAndSettle();

    expect(platformCalls.map((call) => call.method), ['start', 'stop']);

    await pressKey('up');
    await tester.pump();
    verifyNever(() => repository.sendKey(any()));
  });
}
