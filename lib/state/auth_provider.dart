import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'dp_token';

  final ApiClient apiClient;
  final AuthService authService;
  final SocketService socketService;

  AuthProvider({
    required this.apiClient,
    required this.authService,
    required this.socketService,
  });

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? token;
  bool loading = false;
  String? errorMessage;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    apiClient.setToken(savedToken);
    try {
      final me = await authService.me();
      token = savedToken;
      user = me;
      status = AuthStatus.authenticated;
      socketService.connect(savedToken);
    } catch (_) {
      await prefs.remove(_tokenKey);
      apiClient.setToken(null);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _runAuthAction(() => authService.login(email, password));
  }

  // Ne connecte pas automatiquement : l'utilisateur doit se reconnecter avec
  // ses identifiants, ce qui declenche systematiquement le controle de
  // photo de profil obligatoire sur le premier login.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? phone,
  }) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await authService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phone: phone,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );
      return true;
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> _runAuthAction(Future<AuthResult> Function() action) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result.token);

      apiClient.setToken(result.token);
      token = result.token;
      user = result.user;
      status = AuthStatus.authenticated;
      socketService.connect(result.token);
      return true;
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(
    List<int> fileBytes,
    String filename,
    String mimeType,
  ) async {
    user = await authService.uploadAvatar(fileBytes, filename, mimeType);
    notifyListeners();
  }

  Future<void> removeAvatar() async {
    user = await authService.removeAvatar();
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    apiClient.setToken(null);
    socketService.disconnect();
    token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
