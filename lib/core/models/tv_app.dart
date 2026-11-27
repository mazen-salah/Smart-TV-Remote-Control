/// Apps the remote can open with one tap, named as the brand names them.
///
/// The id is brand-specific and lives in the implementation: Samsung takes a
/// numeric Tizen app id, webOS a reverse-domain one. See `samsung_apps.dart`
/// and `lg_apps.dart`.
enum TvApp {
  netflix('Netflix'),
  youtube('YouTube'),
  disneyPlus('Disney+'),
  primeVideo('Prime Video');

  const TvApp(this.label);

  /// Shown on the button; these are product names and are not translated.
  final String label;
}
