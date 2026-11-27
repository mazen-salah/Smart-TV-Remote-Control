import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';

extension TvActions on BuildContext {
  void sendTvKey(KeyCodes key) {
    unawaited(HapticFeedback.lightImpact());
    read<TvConnectionBloc>().add(TvSendKeyRequested(key));
  }

  /// Moves the webOS cursor. No haptic: swipes come in bursts and the pad
  /// would buzz non-stop.
  void moveTvPointer({required int dx, required int dy}) {
    read<TvConnectionBloc>().add(TvPointerMoved(dx: dx, dy: dy));
  }

  void clickTvPointer() {
    unawaited(HapticFeedback.selectionClick());
    read<TvConnectionBloc>().add(const TvPointerClicked());
  }
}
