import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/core/services/locale_storage.dart';

/// Holds the language override picked in the app.
///
/// A `null` state means "follow the device language": Flutter then resolves
/// the best match from `AppLocalizations.supportedLocales`.
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._storage) : super(_storage.load());

  final LocaleStorage _storage;

  /// Switches the app language and persists the choice.
  ///
  /// Passing `null` clears the override and returns to the device language.
  Future<void> select(Locale? locale) async {
    if (locale == state) return;
    emit(locale);
    await _storage.save(locale);
  }
}
