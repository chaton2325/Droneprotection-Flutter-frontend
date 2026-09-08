import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Configuration reseau de l'application.
///
/// Cible actuellement le backend local (`npm run dev` dans
/// Droneprotection-Backend, port 4000) pour les tests en cours, connecte a la
/// vraie base PostgreSQL de production (VPS EBYA). Pour revenir au backend
/// deploye (`https://antitheft.mirhosty.com`), surcharger sans recompiler :
/// `flutter run --dart-define=API_BASE_URL=https://antitheft.mirhosty.com/api --dart-define=SOCKET_URL=https://antitheft.mirhosty.com`
///
/// Sur emulateur Android, `localhost` designe l'emulateur lui-meme (pas la
/// machine hote) : on bascule automatiquement sur l'alias `10.0.2.2` dans ce
/// cas precis tant qu'aucune valeur n'est fournie via --dart-define. Un
/// appareil Android physique doit toujours surcharger explicitement avec
/// l'IP LAN de la machine hote (indetectable automatiquement).
class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _socketUrlOverride = String.fromEnvironment('SOCKET_URL');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static String get _localHost => _isAndroid ? '10.0.2.2' : 'localhost';

  static String get apiBaseUrl => _apiBaseUrlOverride.isNotEmpty
      ? _apiBaseUrlOverride
      : 'http://$_localHost:4000/api';

  static String get socketUrl => _socketUrlOverride.isNotEmpty
      ? _socketUrlOverride
      : 'http://$_localHost:4000';

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
