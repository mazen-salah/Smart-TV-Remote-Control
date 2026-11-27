import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/models/tv_app.dart';
import 'package:remote/services/lg/lg_apps.dart';

void main() {
  group('lgAppIdFor', () {
    test('returns a webOS id for every app the UI offers', () {
      for (final app in TvApp.values) {
        expect(lgAppIdFor(app), isNotNull, reason: app.label);
        expect(lgAppIdFor(app), isNotEmpty, reason: app.label);
      }
    });

    test('uses the ids webOS launch points expect', () {
      expect(lgAppIdFor(TvApp.netflix), 'netflix');
      expect(lgAppIdFor(TvApp.youtube), 'youtube.leanback.v4');
      expect(lgAppIdFor(TvApp.disneyPlus), 'com.disney.disneyplus-prod');
      expect(lgAppIdFor(TvApp.primeVideo), 'amazon');
    });

    test('ids are unique: one id cannot open two products', () {
      final ids = TvApp.values.map(lgAppIdFor).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
