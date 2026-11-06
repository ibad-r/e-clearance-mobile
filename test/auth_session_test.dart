import 'dart:convert';

import 'package:e_clearance_mobile/core/auth/auth_repository.dart';
import 'package:e_clearance_mobile/core/auth/token_storage.dart';
import 'package:e_clearance_mobile/core/network/api_client.dart';
import 'package:e_clearance_mobile/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryTokenStorage extends TokenStorage {
  String? value = 'mock-session-token';
  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async { value = token; }
  @override
  Future<void> clear() async { value = null; }
}

void main() {
  test('restores the user from the actual backend /auth/me response envelope', () async {
    final storage = MemoryTokenStorage();
    final api = ApiClient(
      baseUrl: 'http://test/api/v1',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/me');
        expect(request.headers['Authorization'], 'Bearer mock-session-token');
        return http.Response(jsonEncode({'user': {
          'id': '33333333-3333-4333-8333-333333333333',
          'email': 'fictional@example.invalid',
          'fullName': 'Fictional Employee',
          'role': 'EMPLOYEE',
        }}), 200);
      }),
    );
    final auth = AuthRepository(apiClient: api, tokenStorage: storage);
    final user = await auth.restoreSession();
    expect(user?.email, 'fictional@example.invalid');
    expect(user?.role, 'EMPLOYEE');
    expect(auth.currentUser, same(user));
    expect(storage.value, 'mock-session-token');
  });

  test('reports a malformed session response as a controlled API error', () async {
    final api = ApiClient(
      baseUrl: 'http://test/api/v1',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    final auth = AuthRepository(apiClient: api, tokenStorage: MemoryTokenStorage());
    await expectLater(auth.restoreSession(), throwsA(isA<ApiException>()));
  });
}
