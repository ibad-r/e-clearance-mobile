import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'auth_user.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    TokenStorage? tokenStorage,
  })  : _api = apiClient,
        _storage = tokenStorage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _storage;

  AuthUser? currentUser;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final dynamic data;
    try {
      data = await _api.post(
        '/auth/login',
        body: {'email': email.trim(), 'password': password},
      );
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        throw ApiException(
          message: 'Incorrect email or password.',
          statusCode: e.statusCode,
          code: e.code,
        );
      }
      rethrow;
    }

    if (data is! Map ||
        data['accessToken'] is! String ||
        data['user'] is! Map) {
      throw ApiException(message: 'Unexpected response from the server.');
    }

    final user =
    AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    if (user.role != 'EMPLOYEE') {
      throw ApiException(
        message: 'This app is for employee accounts only.',
        statusCode: 403,
      );
    }

    final token = data['accessToken'] as String;
    await _storage.save(token);
    _api.authToken = token;
    currentUser = user;
    return user;
  }

  /// Call at app start. Returns the user if the saved token is still valid.
  Future<AuthUser?> restoreSession() async {
    final token = await _storage.read();
    if (token == null) return null;
    _api.authToken = token;
    try {
      final data = await _api.get('/auth/me');
      if (data is! Map || data['user'] is! Map) {
        throw ApiException(message: 'Unexpected response from the server.');
      }
      currentUser = AuthUser.fromJson(
          Map<String, dynamic>.from(data['user'] as Map));
      return currentUser;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
        return null;
      }
      rethrow; // network/server problem: keep the token, let the UI show an error
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _api.authToken = null;
    currentUser = null;
  }
}