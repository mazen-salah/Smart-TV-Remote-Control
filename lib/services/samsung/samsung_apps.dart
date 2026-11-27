import 'dart:convert';

import 'package:remote/core/models/tv_app.dart';

/// Tizen app ids, as used by the `ed.apps.launch` event on the remote-control
/// channel.
///
/// Tizen ids are not as stable as the webOS ones: they are assigned per app
/// version, and a set from a different year can carry a different id for the
/// same product. These are the ids the 2016+ sets mostly use — a set that
/// ignores one is reported in issue #14 rather than guessed at here. A TV
/// that ignores an id simply stays where it is; nothing is broken.
String? samsungAppIdFor(TvApp app) => switch (app) {
  TvApp.netflix => '11101200001',
  TvApp.youtube => '111299001912',
  TvApp.disneyPlus => '3201901017640',
  TvApp.primeVideo => '3201910019365',
};

/// Frame that asks the TV to bring [appId] to the foreground.
///
/// `to: "host"` addresses the TV itself rather than another device paired to
/// it, which is what every open-source Tizen remote does.
String samsungAppLaunchCommand(String appId) => jsonEncode({
  'method': 'ms.channel.emit',
  'params': {
    'event': 'ed.apps.launch',
    'to': 'host',
    'data': {'appId': appId},
  },
});
