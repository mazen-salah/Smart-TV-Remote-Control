import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/services/tv_token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TvTokenStorage', () {
    test('save then load returns the same token under the prefixed key',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TvTokenStorage(prefs);

      await storage.save('AA:BB:CC', 'tok-123');

      expect(storage.load('AA:BB:CC'), 'tok-123');
      expect(prefs.getString('tv_token::AA:BB:CC'), 'tok-123');
    });

    test('load returns null for empty identifier and for missing keys',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TvTokenStorage(prefs);

      expect(storage.load(''), isNull);
      expect(storage.load('never-saved'), isNull);
    });

    test('clear removes only the given identifier', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TvTokenStorage(prefs);
      await storage.save('one', 't1');
      await storage.save('two', 't2');

      await storage.clear('one');

      expect(storage.load('one'), isNull);
      expect(storage.load('two'), 't2');
    });

    test('clearAll removes only tv_token:: keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('unrelated', 'keep-me');
      final storage = TvTokenStorage(prefs);
      await storage.save('one', 't1');
      await storage.save('two', 't2');

      await storage.clearAll();

      expect(storage.load('one'), isNull);
      expect(storage.load('two'), isNull);
      expect(prefs.getString('unrelated'), 'keep-me');
    });
  });
}
