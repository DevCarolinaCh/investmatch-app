import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthService(api);
});

// Estado de autenticación: null = no logueado, UserModel = logueado
final authStateProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final isLoggedIn = await authService.isLoggedIn;
  if (!isLoggedIn) return null;
  return authService.getCurrentUser();
});

// Notifier para manejar acciones de auth
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final isLoggedIn = await _authService.isLoggedIn;
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _authService.login(email: email, password: password);
    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
      return null;
    } else {
      state = const AsyncValue.data(null);
      return result.errorMessage;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authService.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
      return null;
    } else {
      state = const AsyncValue.data(null);
      return result.errorMessage;
    }
  }

  Future<String?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _authService.signInWithGoogle();
    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
      return null;
    } else {
      state = const AsyncValue.data(null);
      return result.errorMessage;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
