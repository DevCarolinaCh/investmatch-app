import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.kAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Intentar refresh del token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Reintentar la request original
        final opts = error.requestOptions;
        final token = await _storage.read(key: AppConstants.kAccessToken);
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(error);
        }
      } else {
        // Token expirado: limpiar sesión
        await _storage.deleteAll();
      }
    }
    return handler.next(error);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.kRefreshToken);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _storage.write(
          key: AppConstants.kAccessToken,
          value: data['accessToken'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // AUTH
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await _dio.post('/auth/google', data: {'idToken': idToken});
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await _storage.deleteAll();
    }
  }

  // PROJECTS
  Future<Map<String, dynamic>> getProjects({
    int page = 1,
    String? vertical,
    String? stage,
    String? ticket,
    String? province,
    String? impact,
    String? search,
    bool? highlighted,
  }) async {
    final response = await _dio.get('/projects', queryParameters: {
      'page': page,
      'limit': AppConstants.pageSize,
      if (vertical != null) 'vertical': vertical,
      if (stage != null) 'stage': stage,
      if (ticket != null) 'ticket': ticket,
      if (province != null) 'province': province,
      if (impact != null) 'impact': impact,
      if (search != null && search.isNotEmpty) 'search': search,
      if (highlighted != null) 'highlighted': highlighted,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProject(String id) async {
    final response = await _dio.get('/projects/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProject(Map<String, dynamic> data) async {
    final response = await _dio.post('/projects', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProject(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/projects/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete('/projects/$id');
  }

  Future<Map<String, dynamic>> uploadProjectImage(
    String projectId,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/projects/$projectId/images',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadPitchDeck(
    String projectId,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/projects/$projectId/pitch-deck',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  // FAVORITOS / PIPELINE
  Future<List<dynamic>> getFavorites() async {
    final response = await _dio.get('/favorites');
    return response.data as List;
  }

  Future<void> addFavorite(String projectId) async {
    await _dio.post('/favorites/$projectId');
  }

  Future<void> removeFavorite(String projectId) async {
    await _dio.delete('/favorites/$projectId');
  }

  Future<List<dynamic>> getPipeline() async {
    final response = await _dio.get('/pipeline');
    return response.data as List;
  }

  Future<Map<String, dynamic>> updatePipelineStage(
    String entryId,
    String stage, {
    String? notes,
  }) async {
    final response = await _dio.patch('/pipeline/$entryId', data: {
      'stage': stage,
      if (notes != null) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToPipeline(String projectId) async {
    final response = await _dio.post('/pipeline', data: {'projectId': projectId});
    return response.data as Map<String, dynamic>;
  }

  // MENSAJERÍA
  Future<List<dynamic>> getConversations() async {
    final response = await _dio.get('/conversations');
    return response.data as List;
  }

  Future<Map<String, dynamic>> getOrCreateConversation(
    String projectId,
  ) async {
    final response = await _dio.post('/conversations', data: {
      'projectId': projectId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMessages(
    String conversationId, {
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'limit': 50},
    );
    return response.data as List;
  }

  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
  }) async {
    final response = await _dio.post(
      '/conversations/$conversationId/messages',
      data: {'content': content, 'type': type},
    );
    return response.data as Map<String, dynamic>;
  }

  // AGENDA
  Future<List<dynamic>> getMeetings() async {
    final response = await _dio.get('/meetings');
    return response.data as List;
  }

  Future<Map<String, dynamic>> scheduleMeeting(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/meetings', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMeetingStatus(
    String meetingId,
    String status,
  ) async {
    final response = await _dio.patch('/meetings/$meetingId', data: {
      'status': status,
    });
    return response.data as Map<String, dynamic>;
  }

  // ANALYTICS (para emprendedores)
  Future<Map<String, dynamic>> getProjectAnalytics(String projectId) async {
    final response = await _dio.get('/projects/$projectId/analytics');
    return response.data as Map<String, dynamic>;
  }

  // PERFIL
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/users/me', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/users/me/avatar', data: formData);
    return response.data as Map<String, dynamic>;
  }

  // KYC
  Future<Map<String, dynamic>> startKyc() async {
    final response = await _dio.post('/kyc/start');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitKycDocuments({
    required String frontDocPath,
    required String backDocPath,
    required String selfiePath,
  }) async {
    final formData = FormData.fromMap({
      'frontDoc': await MultipartFile.fromFile(frontDocPath),
      'backDoc': await MultipartFile.fromFile(backDocPath),
      'selfie': await MultipartFile.fromFile(selfiePath),
    });
    final response = await _dio.post('/kyc/submit', data: formData);
    return response.data as Map<String, dynamic>;
  }

  // PAGOS
  Future<Map<String, dynamic>> createPaymentPreference({
    required String plan,
    required String billingCycle,
  }) async {
    final response = await _dio.post('/payments/preference', data: {
      'plan': plan,
      'billingCycle': billingCycle,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubscription() async {
    final response = await _dio.get('/payments/subscription');
    return response.data as Map<String, dynamic>;
  }

  // REPORTES / MODERACIÓN
  Future<void> reportUser(String userId, String reason) async {
    await _dio.post('/moderation/report-user', data: {
      'userId': userId,
      'reason': reason,
    });
  }

  Future<void> reportProject(String projectId, String reason) async {
    await _dio.post('/moderation/report-project', data: {
      'projectId': projectId,
      'reason': reason,
    });
  }

  // PUSH NOTIFICATIONS - registrar token
  Future<void> registerPushToken(String token, String platform) async {
    await _dio.post('/notifications/token', data: {
      'token': token,
      'platform': platform,
    });
  }
}
