/// Configuration reseau de l'application.
///
/// Par defaut on cible le backend de production :
/// - `https://antitheft.mirhosty.com` (HTTPS)
///
/// Ces valeurs peuvent etre surchargees sans recompiler le code source :
/// `flutter run --dart-define=API_BASE_URL=https://antitheft.mirhosty.com/api --dart-define=SOCKET_URL=https://antitheft.mirhosty.com`
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://antitheft.mirhosty.com/api',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://antitheft.mirhosty.com',
  );

  /// Intervalle d'envoi de la position pendant une alerte active.
  static const Duration locationUpdateInterval = Duration(seconds: 6);
}
