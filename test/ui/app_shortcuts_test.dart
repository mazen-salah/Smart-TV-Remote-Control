import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/models/tv_app.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/remote_control/remote_screen.dart';
import 'package:remote/ui/widgets/remote_controls/components/app_shortcuts.dart';
import 'package:remote/ui/widgets/remote_controls/components/num_pad.dart';

class _MockTvRepository extends Mock implements TvRepository {}

class _FakeTvDevice extends Fake implements TVDevice {}

void main() {
  late _MockTvRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeTvDevice());
    registerFallbackValue(TvApp.netflix);
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
    when(() => repository.launchApp(any())).thenAnswer((_) async {});
    when(() => repository.current).thenReturn(null);
  });

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  group('AppShortcuts', () {
    testWidgets('offers one shortcut per app', (tester) async {
      await tester.pumpWidget(wrap(const AppShortcuts()));

      for (final app in TvApp.values) {
        expect(find.text(app.label), findsOneWidget, reason: app.label);
      }
    });

    testWidgets('all four shortcuts fit a 320 dp row', (tester) async {
      await tester.pumpWidget(
        wrap(const SizedBox(width: 320, child: AppShortcuts())),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppShortcuts), findsOneWidget);
    });

    testWidgets('opening an app reaches the TV through the bloc', (
      tester,
    ) async {
      final bloc = TvConnectionBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(TvConnectRequested(TVDevice(host: '10.0.0.5')));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: AppShortcuts()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Netflix'));
      await tester.pump();

      verify(() => repository.launchApp(TvApp.netflix)).called(1);
    });

    testWidgets('does nothing to the TV when no set is connected', (
      tester,
    ) async {
      final bloc = TvConnectionBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: AppShortcuts()),
          ),
        ),
      );

      await tester.tap(find.text('YouTube'));
      await tester.pump();

      verifyNever(() => repository.launchApp(any()));
    });
  });

  group('remote screen with the app row', () {
    // 400 x 900 rather than the narrowest phone: the media row already
    // overflows below 380 dp on this base, which is a separate layout fix
    // (#45). Nothing here touches that row.
    Future<void> pumpRemote(WidgetTester tester, Size logicalSize) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = logicalSize * 3;
      addTearDown(tester.view.reset);

      final bloc = TvConnectionBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(TvConnectRequested(TVDevice(host: '10.0.0.5')));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(value: bloc, child: const RemoteScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the row and opens an app from it', (tester) async {
      await pumpRemote(tester, const Size(400, 900));

      expect(find.byType(AppShortcuts), findsOneWidget);

      await tester.ensureVisible(find.text('Netflix'));
      await tester.tap(find.text('Netflix'));
      await tester.pump();

      verify(() => repository.launchApp(TvApp.netflix)).called(1);
    });

    testWidgets('the keypad and the shortcuts coexist', (tester) async {
      await pumpRemote(tester, const Size(400, 900));

      await tester.tap(find.byIcon(Icons.dialpad));
      await tester.pumpAndSettle();

      expect(find.byType(AppShortcuts), findsOneWidget);
      expect(find.byType(NumPad), findsOneWidget);
    });

    testWidgets('the shortcuts stay on screen when they do not fit', (
      tester,
    ) async {
      await pumpRemote(tester, const Size(400, 700));

      expect(find.byType(AppShortcuts), findsOneWidget);
      await tester.ensureVisible(find.text('Prime Video'));

      expect(find.byType(AppShortcuts), findsOneWidget);
    });
  });
}
