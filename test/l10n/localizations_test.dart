import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/l10n/app_localizations.dart';

void main() {
  group('foundCount', () {
    test(
      'Russian picks the right plural form and interpolates the count',
      () async {
        final l = await AppLocalizations.delegate.load(const Locale('ru'));

        expect(l.foundCount(0), 'Устройства не найдены');
        expect(l.foundCount(1), 'Найдено 1 устройство');
        expect(l.foundCount(2), 'Найдено 2 устройства');
        expect(l.foundCount(5), 'Найдено 5 устройств');
        // Russian takes the singular form for 21, 31, … but the plural one for 11.
        expect(l.foundCount(21), 'Найдено 21 устройство');
        expect(l.foundCount(11), 'Найдено 11 устройств');
      },
    );

    test('every locale shows the count, none leaks the ICU "#"', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);

        expect(l.foundCount(3), contains('3'), reason: locale.toString());
        expect(
          l.foundCount(3),
          isNot(contains('#')),
          reason: locale.toString(),
        );
      }
    });
  });
}
