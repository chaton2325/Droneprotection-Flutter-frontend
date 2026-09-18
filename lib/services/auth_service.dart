import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult(this.token, this.user);
}

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  Future<AuthResult> login(String email, String password) async {
    final data = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthResult(data['token'] as String, AppUser.fromJson(data['user']));
  }

  Future<AuthResult> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? phone,
  }) async {
    final data = await _client.post(
      '/auth/register',
      body: {
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return AuthResult(data['token'] as String, AppUser.fromJson(data['user']));
  }

  Future<AppUser> updateLocationSharing(bool enabled) async {
    final data = await _client.patch(
      '/users/me/location-sharing',
      body: {'enabled': enabled},
    );
    return AppUser.fromJson(data['user']);
  }

  /// Active/desactive la position en direct (independante des alertes) : voir
  /// LiveLocationProvider pour l'envoi periodique tant que c'est actif.
  Future<AppUser> updateLiveLocationSharing(bool enabled) async {
    final data = await _client.patch(
      '/users/me/live-location-sharing',
      body: {'enabled': enabled},
    );
    return AppUser.fromJson(data['user']);
  }

  /// Retourne false si le serveur considere le partage inactif (l'utilisateur
  /// a pu le desactiver depuis un autre appareil) : LiveLocationProvider s'en
  /// sert pour arreter d'essayer plutot que de continuer a l'aveugle.
  Future<bool> pushLiveLocation(double latitude, double longitude) async {
    final data = await _client.post(
      '/users/me/location',
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return data['active'] as bool? ?? false;
  }

  Future<AppUser> me() async {
    final data = await _client.get('/auth/me');
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> uploadAvatar(
    List<int> fileBytes,
    String filename,
    String mimeType,
  ) async {
    final data = await _client.postMultipart(
      '/users/me/avatar',
      fieldName: 'avatar',
      fileBytes: fileBytes,
      filename: filename,
      mimeType: mimeType,
    );
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> removeAvatar() async {
    final data = await _client.delete('/users/me/avatar');
    return AppUser.fromJson(data['user']);
  }

  /// Verifie la disponibilite d'un @nom d'utilisateur pendant la saisie du
  /// formulaire d'inscription, avant que le reste des champs soit rempli.
  Future<bool> isUsernameAvailable(String username) async {
    final data = await _client.get(
      '/auth/check-username',
      query: {'username': username},
    );
    return data['available'] as bool;
  }
}
