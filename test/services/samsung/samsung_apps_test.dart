import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_app.dart';
import 'package:remote/services/samsung/samsung_apps.dart';

void main() {
  group('samsungAppIdFor', () {
    test('returns a Tizen id for every app the UI offers', () {
      for (final app in TvApp.values) {
        expect(samsungAppIdFor(app), isNotNull, reason: app.label);
      }
    });

    test('uses the Tizen ids for the shipped apps', () {
      expect(samsungAppIdFor(TvApp.netflix), '11101200001');
      expect(samsungAppIdFor(TvApp.youtube), '111299001912');
      expect(samsungAppIdFor(TvApp.disneyPlus), '3201901017640');
      expect(samsungAppIdFor(TvApp.primeVideo), '3201910019365');
    });

    test('ids are unique', () {
      final ids = TvApp.values.map(samsungAppIdFor).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('samsungAppLaunchCommand', () {
    test('emits the launch event for the TV itself', () {
      final frame =
          jsonDecode(samsungAppLaunchCommand('11101200001'))
              as Map<String, dynamic>;

      expect(frame['method'], 'ms.channel.emit');
      final params = frame['params'] as Map<String, dynamic>;
      expect(params['event'], 'ed.apps.launch');
      expect(params['to'], 'host');
      expect(params['data'], {'appId': '11101200001'});
    });
  });
}
