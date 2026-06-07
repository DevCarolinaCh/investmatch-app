import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthService(this._api);

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: AppConstants.kAccessToken);
    return token != null;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final data = await _api.getMe();
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.login(email: email, password: password);
      await _saveTokens(data);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return AuthResult.success(user);
    } on Exception catch (e) {
      return AuthResult.error(_parseError(e));
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final data = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role.name,
      );
      await _saveTokens(data);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return AuthResult.success(user);
    } on Exception catch (e) {
      return AuthResult.error(_parseError(e));
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return AuthResult.error('Inicio con Google cancelado');

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return AuthResult.error('Error de autenticación con Google');

      final data = await _api.loginWithGoogle(idToken);
      await _saveTokens(data);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return AuthResult.success(user);
    } on Exception catch (e) {
      return AuthResult.error(_parseError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
      await _googleSignIn.signOut();
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await Future.wait([
      _storage.write(
        key: AppConstants.kAccessToken,
        value: data['accessToken'] as String,
      ),
      _storage.write(
        key: AppConstants.kRefreshToken,
        value: data['refreshToken'] as String,
      ),
      _storage.write(
        key: AppConstants.kUserId,
        value: (data['user'] as Map<String, dynamic>)['id'] as String,
      ),
      _storage.write(
        key: AppConstants.kUserRole,
        value: (data['user'] as Map<String, dynamic>)['role'] as String,
      ),
    ]);
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('401')) return 'Email o contraseña incorrectos';
    if (message.contains('409')) return 'Este email ya está registrado';
    if (message.contains('network')) return 'Sin conexión. Verificá tu internet';
    return 'Ocurrió un error. Intentá nuevamente';
  }
}

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(UserModel user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.error(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
