import 'package:remote/core/models/tv_app.dart';

/// webOS app ids for the launch request
/// (`ssap://system.launcher/launch` with `{"id": <value>}`).
///
/// These are the ids the sets themselves use in
/// `ssap://com.webos.applicationManager/listLaunchPoints`; they are stable
/// across webOS versions and not model-specific, unlike the Tizen ones.
String? lgAppIdFor(TvApp app) => switch (app) {
  TvApp.netflix => 'netflix',
  TvApp.youtube => 'youtube.leanback.v4',
  TvApp.disneyPlus => 'com.disney.disneyplus-prod',
  TvApp.primeVideo => 'amazon',
};
