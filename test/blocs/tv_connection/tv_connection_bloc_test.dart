import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';

class _MockTvRepository extends Mock implements TvRepository {}

class _FakeTvDevice extends Fake implements TVDevice {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTvDevice());
    registerFallbackValue(KeyCodes.KEY_POWER);
  });

  late _MockTvRepository repository;
  final device = TVDevice(
    host: '10.0.0.5',
    mac: 'AA:BB:CC',
    deviceName: 'Living Room',
  );

  setUp(() {
    repository = _MockTvRepository();
    // Sensible defaults for void-returning methods so unrelated calls
    // don't blow up with "Null is not a subtype of Future<void>".
    when(() => repository.disconnect()).thenAnswer((_) => Future<void>.value());
    when(
      () => repository.forgetCurrent(),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => repository.sendKey(any()),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => repository.connect(
        any(),
        onDisconnected: any(named: 'onDisconnected'),
      ),
    ).thenAnswer((_) => Future<void>.value());
  });

  group('TvConnectionBloc', () {
    blocTest<TvConnectionBloc, TvConnectionState>(
      'connect: emits connecting -> connected on success',
      build: () => TvConnectionBloc(repository: repository),
      act: (bloc) => bloc.add(TvConnectRequested(device)),
      expect: () => [
        isA<TvConnectionState>()
            .having((s) => s.status, 'status', TvConnectionStatus.connecting)
            .having((s) => s.device, 'device', device),
        isA<TvConnectionState>().having(
          (s) => s.status,
          'status',
          TvConnectionStatus.connected,
        ),
      ],
    );

    blocTest<TvConnectionBloc, TvConnectionState>(
      'connect: emits connecting -> error when repository throws',
      build: () {
        when(
          () => repository.connect(
            any(),
            onDisconnected: any(named: 'onDisconnected'),
          ),
        ).thenThrow(Exception('boom'));
        return TvConnectionBloc(repository: repository);
      },
      act: (bloc) => bloc.add(TvConnectRequested(device)),
      expect: () => [
        isA<TvConnectionState>().having(
          (s) => s.status,
          'status',
          TvConnectionStatus.connecting,
        ),
        isA<TvConnectionState>()
            .having((s) => s.status, 'status', TvConnectionStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );

    blocTest<TvConnectionBloc, TvConnectionState>(
      'sendKey: delegates to repository when connected, emits nothing',
      build: () => TvConnectionBloc(repository: repository),
      seed: () => const TvConnectionState(status: TvConnectionStatus.connected),
      act: (bloc) => bloc.add(const TvSendKeyRequested(KeyCodes.KEY_VOLUP)),
      expect: () => const <TvConnectionState>[],
      verify: (_) {
        verify(() => repository.sendKey(KeyCodes.KEY_VOLUP)).called(1);
      },
    );

    blocTest<TvConnectionBloc, TvConnectionState>(
      'sendKey: is a no-op when not connected',
      build: () => TvConnectionBloc(repository: repository),
      act: (bloc) => bloc.add(const TvSendKeyRequested(KeyCodes.KEY_VOLUP)),
      expect: () => const <TvConnectionState>[],
      verify: (_) {
        verifyNever(() => repository.sendKey(any()));
      },
    );

    blocTest<TvConnectionBloc, TvConnectionState>(
      'disconnect: emits disconnected with userInitiated reason',
      build: () => TvConnectionBloc(repository: repository),
      seed: () => const TvConnectionState(status: TvConnectionStatus.connected),
      act: (bloc) => bloc.add(const TvDisconnectRequested()),
      expect: () => [
        isA<TvConnectionState>()
            .having((s) => s.status, 'status', TvConnectionStatus.disconnected)
            .having(
              (s) => s.disconnectionType,
              'reason',
              DisconnectionType.userInitiated,
            ),
      ],
    );

    blocTest<TvConnectionBloc, TvConnectionState>(
      'forget: clears repository and resets state to idle',
      build: () => TvConnectionBloc(repository: repository),
      seed: () => TvConnectionState(
        status: TvConnectionStatus.connected,
        device: device,
      ),
      act: (bloc) => bloc.add(const TvForgetRequested()),
      expect: () => [const TvConnectionState.idle()],
      verify: (_) {
        verify(() => repository.forgetCurrent()).called(1);
      },
    );
  });
}
