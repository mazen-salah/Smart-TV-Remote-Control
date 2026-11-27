import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the language the user picked inside the app so the choice
/// survives a restart. A `null` locale means "follow the device language".
class LocaleStorage {
  LocaleStorage(this._prefs);

  static const String _localeKey = 'locale_code';

  final SharedPreferences _prefs;

  Locale? load() {
    final code = _prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> save(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_localeKey);
      return;
    }
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}
