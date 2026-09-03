/// Configuration reseau de l'application.
///
/// Par defaut on cible un backend lance en local (`npm run dev` dans
/// Droneprotection-Backend) :
/// - `10.0.2.2` est l'adresse de l'hote depuis un emulateur Android.
/// - Sur un simulateur iOS ou en desktop/web, utilisez `localhost`.
/// - Sur un appareil physique, utilisez l'adresse IP locale de votre machine
///   (ex: 192.168.1.42) et le meme reseau Wi-Fi.
///
/// Ces valeurs peuvent etre surchargees sans recompiler le code source :
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.42:4000/api --dart-define=SOCKET_URL=http://192.168.1.42:4000`
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  /// Intervalle d'envoi de la position pendant une alerte active.
  static const Duration locationUpdateInterval = Duration(seconds: 6);
}
