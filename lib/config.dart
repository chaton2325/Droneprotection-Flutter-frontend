/// Configuration reseau de l'application.
///
/// Par defaut on cible le backend de production :
/// - `https://antitheft.mirhosty.com` (HTTPS)
///
/// Ces valeurs peuvent etre surchargees sans recompiler le code source, par
/// exemple pour pointer vers un backend local en developpement :
/// `flutter run --dart-define=API_BASE_URL=http://localhost:4000/api --dart-define=SOCKET_URL=http://localhost:4000`
///
/// Sur emulateur Android, `localhost` designe l'emulateur lui-meme (pas la
/// machine hote) : utiliser `--dart-define=API_BASE_URL=http://10.0.2.2:4000/api --dart-define=SOCKET_URL=http://10.0.2.2:4000`
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

  /// Origine du backend (sans le `/api` final) : les avatars sont servis en
  /// statique a la racine (/uploads/avatars/...), pas sous /api.
  static String get _origin => apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// `user.avatarUrl` / `alert.responderAvatarUrl` sont des chemins relatifs
  /// (/uploads/avatars/xxx.png) : on les prefixe par l'origine du backend.
  static String? resolveAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    return '$_origin$avatarUrl';
  }
}
