import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_event.dart';
import 'package:remote/blocs/tv_connection/tv_connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/repositories/tv_repository.dart';

export 'tv_connection_event.dart';
export 'tv_connection_state.dart';

class TvConnectionBloc extends Bloc<TvConnectionEvent, TvConnectionState> {
  TvConnectionBloc({required TvRepository repository})
    : _repository = repository,
      super(const TvConnectionState.idle()) {
    on<TvConnectRequested>(_onConnectRequested);
    on<TvDisconnectRequested>(_onDisconnectRequested);
    on<TvSendKeyRequested>(_onSendKeyRequested);
    on<TvForgetRequested>(_onForgetRequested);
    on<TvDisconnectionDetected>(_onDisconnectionDetected);
  }

  final TvRepository _repository;

  /// Bumped by forget/disconnect so a connect that finishes afterwards is
  /// discarded instead of resurrecting the TV.
  int _generation = 0;

  Future<void> _onConnectRequested(
    TvConnectRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    // A second tap while a connect (and possibly a pairing prompt) is in
    // flight would open a second socket and a second prompt.
    if (state.isConnecting) return;
    emit(
      state.copyWith(
        status: TvConnectionStatus.connecting,
        device: event.device,
        clearError: true,
        clearDisconnection: true,
      ),
    );

    final generation = _generation;
    try {
      await _repository.connect(
        event.device,
        onDisconnected: (type) {
          // Re-enter the bloc from the network callback.
          add(TvDisconnectionDetected(type.name));
        },
      );
      if (generation != _generation) {
        // Forgotten or disconnected while connecting: drop the session.
        await _repository.disconnect();
        return;
      }
      emit(state.copyWith(status: TvConnectionStatus.connected));
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: TvConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDisconnectRequested(
    TvDisconnectRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    _generation++;
    await _repository.disconnect();
    emit(
      state.copyWith(
        status: TvConnectionStatus.disconnected,
        disconnectionType: DisconnectionType.userInitiated,
      ),
    );
  }

  Future<void> _onSendKeyRequested(
    TvSendKeyRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    if (state.status != TvConnectionStatus.connected) return;
    try {
      await _repository.sendKey(event.key);
    } catch (e) {
      // One key failing (e.g. the LG pointer socket being slow) must not
      // take the session down while the main connection is still alive.
      if (_repository.current?.isConnected ?? false) {
        emit(state.copyWith(errorMessage: e.toString()));
        return;
      }
      emit(
        state.copyWith(
          status: TvConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onForgetRequested(
    TvForgetRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    _generation++;
    final device = event.device;
    if (device == null) {
      await _repository.forgetCurrent();
      emit(const TvConnectionState.idle());
      return;
    }
    await _repository.forget(device);
    if (state.device?.host == device.host) {
      emit(const TvConnectionState.idle());
    }
  }

  void _onDisconnectionDetected(
    TvDisconnectionDetected event,
    Emitter<TvConnectionState> emit,
  ) {
    final type = DisconnectionType.values.firstWhere(
      (t) => t.name == event.reason,
      orElse: () => DisconnectionType.unknown,
    );
    emit(
      state.copyWith(
        status: TvConnectionStatus.disconnected,
        disconnectionType: type,
      ),
    );
  }
}
