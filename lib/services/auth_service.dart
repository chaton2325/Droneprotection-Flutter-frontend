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
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final data = await _client.post(
      '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return AuthResult(data['token'] as String, AppUser.fromJson(data['user']));
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
}
