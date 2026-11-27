import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote/l10n/app_localizations.dart';

/// Guards the translation files themselves: every locale has to carry exactly
/// the template's keys and use the same placeholders.
///
/// `flutter gen-l10n` silently falls back to English for a key a locale does
/// not have, and silently drops a key the template does not have. Neither
/// shows up in `flutter analyze`, so this test is what keeps a new language
/// from shipping half-translated.
void main() {
  final files =
      Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final template = files.firstWhere((file) => file.path.endsWith('app_en.arb'));
  final templateJson =
      jsonDecode(template.readAsStringSync()) as Map<String, dynamic>;

  Set<String> keysOf(Map<String, dynamic> json) =>
      json.keys.where((key) => !key.startsWith('@')).toSet();

  /// Placeholder names used inside a message, including ICU plural cases.
  Set<String> placeholdersIn(Object? message) => RegExp(
    r'\{([a-zA-Z_][a-zA-Z0-9_]*)\s*[,}]',
  ).allMatches(message.toString()).map((match) => match.group(1)!).toSet();

  Map<String, dynamic> read(File file) =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  test('the template itself is not empty', () {
    expect(keysOf(templateJson), isNotEmpty);
  });

  test('every locale has the template keys and no others', () {
    final expected = keysOf(templateJson);

    for (final file in files) {
      if (file.path == template.path) continue;
      final locale = read(file);
      expect(
        keysOf(locale).difference(expected),
        isEmpty,
        reason: '${file.path} has keys the template does not',
      );
      expect(
        expected.difference(keysOf(locale)),
        isEmpty,
        reason: '${file.path} is missing template keys',
      );
    }
  });

  test('every locale uses the template placeholders', () {
    final expected = <String, Set<String>>{};
    for (final key in keysOf(templateJson)) {
      final message = templateJson[key];
      if (message is! Map<String, dynamic>) continue;
      final placeholders = message['placeholders'];
      if (placeholders is! Map<String, dynamic>) continue;
      expected[key] = placeholders.keys.toSet();
    }

    for (final file in files) {
      if (file.path == template.path) continue;
      final locale = read(file);
      final name = file.uri.pathSegments.last;

      for (final entry in expected.entries) {
        expect(
          placeholdersIn(locale[entry.key]),
          entry.value,
          reason: '$name.${entry.key}: placeholders must match the template',
        );
      }
    }
  });

  test('the language codes are the ones the app advertises', () {
    expect(
      files.map((file) => file.uri.pathSegments.last).toList(),
      containsAll(<String>[
        'app_en.arb',
        'app_es.arb',
        'app_ar.arb',
        'app_fr.arb',
        'app_de.arb',
        'app_pt.arb',
      ]),
    );
  });

  test('the device counter renders in every locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);

      // A broken ICU string shows up as a literal brace or a missing number.
      expect(l.foundCount(2), contains('2'), reason: locale.toString());
      expect(l.foundCount(2), isNot(contains('{')), reason: locale.toString());
      expect(l.foundCount(1), contains('1'), reason: locale.toString());
    }
  });
}
