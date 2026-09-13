import 'package:flutter/material.dart';

class AppTheme {
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceVariant = Color(0xFF2E2E2E);
  static const Color _accent = Color(0xFF00D4FF);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _surface,
      colorScheme: base.colorScheme.copyWith(
        primary: _accent,
        secondary: _accent,
        surface: _surface,
        surfaceContainerHighest: _surfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: const CardThemeData(color: Color(0xFF1F1F1F), elevation: 0),
    );
  }
}
