import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/tv_app.dart';

extension TvActions on BuildContext {
  void sendTvKey(KeyCodes key) {
    unawaited(HapticFeedback.lightImpact());
    read<TvConnectionBloc>().add(TvSendKeyRequested(key));
  }

  /// Opens [app] on the connected TV.
  void openTvApp(TvApp app) {
    unawaited(HapticFeedback.lightImpact());
    read<TvConnectionBloc>().add(TvAppLaunchRequested(app));
  }
}
