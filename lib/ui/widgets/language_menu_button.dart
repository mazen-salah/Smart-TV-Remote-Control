import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/locale/locale_cubit.dart';
import 'package:remote/l10n/app_localizations.dart';

/// App-bar menu that overrides the app language.
///
/// The choice is persisted by [LocaleCubit]; "System default" clears it so
/// the app follows the device again.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  /// Values are plain language codes; `_system` clears the override.
  /// A `PopupMenuButton` cannot use `null` as an item value — it treats a
  /// `null` result as a cancelled menu.
  static const String _system = 'system';

  static const List<String> _codes = <String>['en', 'ru', 'es', 'ar'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selected = context.watch<LocaleCubit>().state;
    return PopupMenuButton<String>(
      tooltip: l.language,
      icon: const Icon(Icons.translate),
      onSelected: (value) {
        final locale = value == _system ? null : Locale(value);
        unawaited(context.read<LocaleCubit>().select(locale));
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        CheckedPopupMenuItem<String>(
          value: _system,
          checked: selected == null,
          child: Text(l.languageSystem),
        ),
        for (final code in _codes)
          CheckedPopupMenuItem<String>(
            value: code,
            checked: selected?.languageCode == code,
            child: Text(_label(l, code)),
          ),
      ],
    );
  }

  String _label(AppLocalizations l, String code) => switch (code) {
    'ru' => l.languageRussian,
    'es' => l.languageSpanish,
    'ar' => l.languageArabic,
    _ => l.languageEnglish,
  };
}
