import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'demo_data.dart';

class AuthService {
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Demo mode: si la URL de la API no está configurada, todo es demo
  static const bool _isDemoMode = true;

  AuthService(this._api);

  Future<bool> get isLoggedIn async {
    if (_isDemoMode) {
      final token = await _storage.read(key: AppConstants.kAccessToken);
      return token == 'demo_token';
    }
    final token = await _storage.read(key: AppConstants.kAccessToken);
    return token != null;
  }

  Future<UserModel?> getCurrentUser() async {
    if (_isDemoMode) {
      final role = await _storage.read(key: AppConstants.kUserRole);
      if (role == 'founder') return DemoData.demoFounder;
      return DemoData.demoInvestor;
    }
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
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 900));
      // Cualquier email/password funciona en modo demo
      final isFounder = email.contains('fundador') ||
          email.contains('founder') ||
          email.contains('emprendedor');
      final user = isFounder ? DemoData.demoFounder : DemoData.demoInvestor;
      await _saveDemoSession(user);
      return AuthResult.success(user);
    }
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
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      final user = role == UserRole.founder
          ? DemoData.demoFounder.copyWith(email: email, fullName: fullName)
          : DemoData.demoInvestor.copyWith(email: email, fullName: fullName);
      await _saveDemoSession(user);
      return AuthResult.success(user);
    }
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
    return AuthResult.error('Google Sign-In disponible en la app móvil');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> _saveDemoSession(UserModel user) async {
    await Future.wait([
      _storage.write(key: AppConstants.kAccessToken, value: 'demo_token'),
      _storage.write(key: AppConstants.kRefreshToken, value: 'demo_refresh'),
      _storage.write(key: AppConstants.kUserId, value: user.id),
      _storage.write(key: AppConstants.kUserRole, value: user.role.name),
    ]);
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
