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

  Future<void> _onConnectRequested(
    TvConnectRequested event,
    Emitter<TvConnectionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TvConnectionStatus.connecting,
        device: event.device,
        clearError: true,
        clearDisconnection: true,
      ),
    );

    try {
      await _repository.connect(
        event.device,
        onDisconnected: (type) {
          // Re-enter the bloc from the network callback.
          add(TvDisconnectionDetected(type.name));
        },
      );
      emit(state.copyWith(status: TvConnectionStatus.connected));
    } catch (e) {
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
    await _repository.forgetCurrent();
    emit(const TvConnectionState.idle());
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
