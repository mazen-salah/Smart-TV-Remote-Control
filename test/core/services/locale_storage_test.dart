import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/core/services/locale_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleStorage', () {
    test('load returns null when the user never picked a language', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocaleStorage(prefs);

      expect(storage.load(), isNull);
    });

    test('save persists the language code and load reads it back', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocaleStorage(prefs);

      await storage.save(const Locale('ru'));

      expect(storage.load(), const Locale('ru'));
    });

    test('save overrides an earlier choice', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocaleStorage(prefs);

      await storage.save(const Locale('ru'));
      await storage.save(const Locale('es'));

      expect(storage.load(), const Locale('es'));
    });

    test(
      'save(null) forgets the choice and follows the device again',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final storage = LocaleStorage(prefs);

        await storage.save(const Locale('ru'));
        await storage.save(null);

        expect(storage.load(), isNull);
        expect(prefs.getString('locale_code'), isNull);
      },
    );

    test('only the language code is stored, not the region', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocaleStorage(prefs);

      await storage.save(const Locale('pt', 'BR'));

      expect(prefs.getString('locale_code'), 'pt');
      expect(storage.load(), const Locale('pt'));
    });

    test('an empty stored code means no choice', () async {
      SharedPreferences.setMockInitialValues({'locale_code': ''});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocaleStorage(prefs);

      expect(storage.load(), isNull);
    });
  });
}
