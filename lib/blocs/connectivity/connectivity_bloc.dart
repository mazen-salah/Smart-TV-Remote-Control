import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/connectivity/connectivity_state.dart';

export 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityStateView> {
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityStateView.unknown()) {
    _bootstrap();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _bootstrap() async {
    emit(ConnectivityStateView(await _connectivity.checkConnectivity()));
    _sub = _connectivity.onConnectivityChanged.listen(
      (results) => emit(ConnectivityStateView(results)),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
