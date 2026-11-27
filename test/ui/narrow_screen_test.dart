import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/remote_control/remote_screen.dart';

class _MockTvRepository extends Mock implements TvRepository {}

class _FakeTvDevice extends Fake implements TVDevice {}

/// The remote is a dense column of fixed-size controls, and the media row used
/// to overflow on a 360 dp phone — the width of most budget Android handsets.
void main() {
  late _MockTvRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeTvDevice());
    registerFallbackValue(KeyCodes.KEY_PLAY);
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
    when(() => repository.sendKey(any())).thenAnswer((_) async {});
    when(() => repository.current).thenReturn(null);
  });

  Future<void> pumpRemote(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = logicalSize * 3;
    addTearDown(tester.view.reset);

    final bloc = TvConnectionBloc(repository: repository);
    addTearDown(bloc.close);
    bloc.add(
      TvConnectRequested(TVDevice(host: '10.0.0.5', deviceName: 'Living Room')),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: bloc, child: const RemoteScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('narrow phones', () {
    testWidgets('360 dp wide lays the remote out without overflow', (
      tester,
    ) async {
      await pumpRemote(tester, logicalSize: const Size(360, 800));

      expect(tester.takeException(), isNull);
    });

    testWidgets('320 dp wide, the smallest common phone', (tester) async {
      await pumpRemote(tester, logicalSize: const Size(320, 640));

      expect(tester.takeException(), isNull);
    });

    testWidgets('the numeric keypad fits too', (tester) async {
      await pumpRemote(tester, logicalSize: const Size(360, 800));

      await tester.tap(find.byIcon(Icons.dialpad));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('every media button stays reachable at 360 dp', (tester) async {
      await pumpRemote(tester, logicalSize: const Size(360, 800));

      for (final icon in [
        Icons.fast_rewind,
        Icons.fiber_manual_record,
        Icons.play_arrow,
        Icons.stop,
        Icons.pause,
        Icons.fast_forward,
      ]) {
        expect(find.byIcon(icon), findsOneWidget, reason: '$icon is missing');
      }

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      verify(() => repository.sendKey(KeyCodes.KEY_PLAY)).called(1);
    });
  });
}
