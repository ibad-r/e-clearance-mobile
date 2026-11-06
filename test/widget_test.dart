import 'dart:convert';

import 'package:e_clearance_mobile/core/app_state.dart';
import 'package:e_clearance_mobile/core/auth/auth_repository.dart';
import 'package:e_clearance_mobile/core/auth/token_storage.dart';
import 'package:e_clearance_mobile/core/network/api_client.dart';
import 'package:e_clearance_mobile/core/network/api_exception.dart';
import 'package:e_clearance_mobile/core/routes.dart';
import 'package:e_clearance_mobile/core/theme/app_theme.dart';
import 'package:e_clearance_mobile/data/clearance_repository.dart';
import 'package:e_clearance_mobile/models/clearance_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

// All data below is made-up test data. No real employee data or real
// credentials are used anywhere in these tests.
const _email = 'test.employee@example.com';
const _password = 'test-password';
const _token = 'test-token';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _error(String code, String message) => {
  'error': {'code': code, 'message': message},
};

Map<String, dynamic> _caseJson() => {
  'id': '11111111-1111-1111-1111-111111111111',
  'requestCode': 'TEST-0001',
  'employeeId': '22222222-2222-2222-2222-222222222222',
  'status': 'IN_PROGRESS',
  'reasonForLeaving': 'Contract Completion',
  'lastWorkingDate': '2026-11-10',
  'employeeRemarks': null,
  'initiatedAt': '2026-11-03T10:00:00.000Z',
  'submittedAt': '2026-11-03T10:00:00.000Z',
  'completedAt': null,
  'cancelledAt': null,
  'stages': [
    {
      'id': 's2',
      'departmentId': 'd2',
      'departmentCode': 'LIB',
      'departmentName': 'Test Library',
      'stepOrder': 2,
      'isRequired': true,
      'status': 'LOCKED',
      'outstandingNote': null,
    },
    {
      'id': 's1',
      'departmentId': 'd1',
      'departmentCode': 'FIN',
      'departmentName': 'Test Finance',
      'stepOrder': 1,
      'isRequired': true,
      'status': 'LOCKED',
      'outstandingNote': null,
    },
  ],
  'approvals': [
    {
      'id': 'a1',
      'positionId': 'p1',
      'positionTitle': 'Test HOD',
      'stepOrder': 1,
      'isRequired': true,
      'status': 'WAITING',
    },
  ],
  'issues': [],
  'certificateId': null,
  'progress': {
    'totalStages': 2,
    'clearedStages': 0,
    'outstandingStages': 0,
    'skippedStages': 0,
  },
};

/// Keeps the token in memory, so tests never touch the real secure storage.
class _FakeTokenStorage extends TokenStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> save(String token) async {
    _value = token;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}

/// A fake backend that behaves like the real API contract.
class _FakeBackend {
  _FakeBackend({List<Map<String, dynamic>>? cases}) : cases = cases ?? [];

  final List<Map<String, dynamic>> cases;
  final List<http.Request> log = [];

  int count(String method, String path) => log
      .where((r) => r.method == method && r.url.path.endsWith(path))
      .length;

  http.Request lastRequest(String method, String path) => log.lastWhere(
          (r) => r.method == method && r.url.path.endsWith(path));

  Future<http.Response> handle(http.Request r) async {
    log.add(r);
    final path = r.url.path;

    if (r.method == 'POST' && path.endsWith('/auth/login')) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (body['email'] != _email || body['password'] != _password) {
        return _json(401, _error('INVALID_CREDENTIALS', 'Invalid credentials'));
      }
      return _json(200, {
        'data': {
          'accessToken': _token,
          'tokenType': 'Bearer',
          'user': {
            'id': '33333333-3333-3333-3333-333333333333',
            'email': _email,
            'fullName': 'Test Employee',
            'role': 'EMPLOYEE',
          },
        },
      });
    }

    if (r.headers['Authorization'] != 'Bearer $_token') {
      return _json(401, _error('UNAUTHORIZED', 'Token expired'));
    }

    if (r.method == 'GET' && path.endsWith('/employee/profile')) {
      return _json(200, {
        'data': {
          'employeeNumber': 'T-001',
          'fullName': 'Test Employee',
          'designation': 'Test Lecturer',
          'facultyCode': 'FC',
          'departmentName': 'Test Department',
          'joiningDate': '2022-09-01',
          'category': 'TEACHER',
        },
      });
    }

    if (r.method == 'POST' && path.endsWith('/employee/cases')) {
      final created = _caseJson();
      cases.add(created);
      return _json(201, {'data': created});
    }

    if (r.method == 'GET' && path.endsWith('/employee/cases')) {
      return _json(200, {'data': cases});
    }

    return _json(404, _error('NOT_FOUND', 'Not found'));
  }

  ApiClient newClient() => ApiClient(
    httpClient: MockClient(handle),
    baseUrl: 'http://test/api/v1',
  );

  AppState newState() {
    final api = newClient();
    return AppState(
      apiClient: api,
      auth: AuthRepository(apiClient: api, tokenStorage: _FakeTokenStorage()),
    );
  }
}

Widget _buildApp(AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.table,
    ),
  );
}

ClearanceDraft _draft({String? reason, String remarks = ''}) => ClearanceDraft()
  ..lastWorkingDay = DateTime(2026, 11, 10)
  ..reason = reason ?? 'Contract Completion'
  ..remarks = remarks;

void main() {
  group('Login screen', () {
    testWidgets('shows email, password and Log in button', (tester) async {
      await tester.pumpWidget(_buildApp(_FakeBackend().newState()));

      expect(find.text('E-Clearance'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('empty email shows a validation error', (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(_buildApp(backend.newState()));

      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      // Nothing is sent to the server when the form is invalid.
      expect(backend.log, isEmpty);
    });

    testWidgets('wrong password shows the server error', (tester) async {
      await tester.pumpWidget(_buildApp(_FakeBackend().newState()));

      await tester.enterText(find.byType(TextFormField).first, _email);
      await tester.enterText(find.byType(TextFormField).last, 'wrong-pass');
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      // Still on the login screen.
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('correct login opens the dashboard with the real profile',
            (tester) async {
          final backend = _FakeBackend();
          await tester.pumpWidget(_buildApp(backend.newState()));

          await tester.enterText(find.byType(TextFormField).first, _email);
          await tester.enterText(find.byType(TextFormField).last, _password);
          await tester.tap(find.text('Log in'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          expect(find.text('Test Employee'), findsOneWidget);
          expect(find.text('No active clearance'), findsOneWidget);
          expect(find.text('Start Clearance'), findsOneWidget);
          expect(backend.count('GET', '/employee/profile'), 1);
        });
  });

  group('API client and repositories', () {
    test('login sends the token on later requests', () async {
      final backend = _FakeBackend();
      final state = backend.newState();

      await state.login(_email, _password);

      expect(state.employee?.name, 'Test Employee');
      final profileRequest = backend.lastRequest('GET', '/employee/profile');
      expect(profileRequest.headers['Authorization'], 'Bearer $_token');
    });

    test('submit sends exactly the three allowed fields', () async {
      final backend = _FakeBackend();
      final api = backend.newClient()..authToken = _token;
      final repo = ApiClearanceRepository(apiClient: api);

      final result = await repo.submit(_draft(remarks: ''));

      final sent = jsonDecode(backend.lastRequest('POST', '/employee/cases').body)
      as Map<String, dynamic>;
      expect(sent.keys.toSet(),
          {'lastWorkingDate', 'reasonForLeaving', 'employeeRemarks'});
      expect(sent['lastWorkingDate'], '2026-11-10');
      expect(sent['reasonForLeaving'], 'Contract Completion');
      expect(sent['employeeRemarks'], isNull);
      // The request code comes from the server response.
      expect(result.id, 'TEST-0001');
    });

    test('submit sends remarks when the user typed some', () async {
      final backend = _FakeBackend();
      final api = backend.newClient()..authToken = _token;
      final repo = ApiClearanceRepository(apiClient: api);

      await repo.submit(_draft(remarks: 'Handover done'));

      final sent = jsonDecode(backend.lastRequest('POST', '/employee/cases').body)
      as Map<String, dynamic>;
      expect(sent['employeeRemarks'], 'Handover done');
    });

    test('a reason shorter than 3 characters is rejected before sending',
            () async {
          final backend = _FakeBackend();
          final api = backend.newClient()..authToken = _token;
          final repo = ApiClearanceRepository(apiClient: api);

          await expectLater(
            repo.submit(_draft(reason: 'ab')),
            throwsA(isA<ApiException>()
                .having((e) => e.isValidation, 'isValidation', true)),
          );
          expect(backend.count('POST', '/employee/cases'), 0);
        });

    test('a second tap on submit is ignored while the first is running',
            () async {
          final backend = _FakeBackend();
          final state = backend.newState();
          await state.login(_email, _password);

          state.draft
            ..lastWorkingDay = DateTime(2026, 11, 10)
            ..reason = 'Contract Completion';

          await Future.wait([state.submit(), state.submit()]);

          expect(backend.count('POST', '/employee/cases'), 1);
        });

    test('the submitted case is loaded back from the server', () async {
      final backend = _FakeBackend();
      final state = backend.newState();
      await state.login(_email, _password);
      expect(state.hasActiveRequest, isFalse);

      state.draft
        ..lastWorkingDay = DateTime(2026, 11, 10)
        ..reason = 'Contract Completion';
      await state.submit();

      // Forget the local copy, then reload from the (fake) backend.
      state.activeRequest = null;
      await state.refreshCases();

      expect(state.hasActiveRequest, isTrue);
      expect(state.activeRequest!.id, 'TEST-0001');
      expect(state.activeRequest!.status, 'IN_PROGRESS');
    });

    test('stages are sorted and show the backend department names', () async {
      final backend = _FakeBackend(cases: [_caseJson()]);
      final api = backend.newClient()..authToken = _token;
      final repo = ApiClearanceRepository(apiClient: api);

      final cases = await repo.listCases();

      expect(cases, hasLength(1));
      expect(cases.first.steps.map((s) => s.department).toList(),
          ['Test Finance', 'Test Library']);
      expect(cases.first.steps.first.status, StepStatus.locked);
      expect(cases.first.totalStages, 2);
      expect(cases.first.approvals.first.status, 'WAITING');
    });

    test('409 ACTIVE_CASE_EXISTS is reported clearly', () async {
      final api = ApiClient(
        httpClient: MockClient((_) async => _json(
            409,
            _error('ACTIVE_CASE_EXISTS',
                'You already have an active clearance request.'))),
        baseUrl: 'http://test/api/v1',
      )..authToken = _token;
      final repo = ApiClearanceRepository(apiClient: api);

      await expectLater(
        repo.submit(_draft()),
        throwsA(isA<ApiException>()
            .having((e) => e.isActiveCaseExists, 'isActiveCaseExists', true)
            .having((e) => e.message, 'message',
            'You already have an active clearance request.')),
      );
    });

    test('an expired token (401) triggers the session-expired callback',
            () async {
          final backend = _FakeBackend();
          var expired = false;
          final api = backend.newClient()
            ..authToken = 'old-token'
            ..onUnauthorized = () => expired = true;

          await expectLater(
            api.get('/employee/cases'),
            throwsA(isA<ApiException>()
                .having((e) => e.isUnauthorized, 'isUnauthorized', true)),
          );
          expect(expired, isTrue);
        });

    test('Logout button clears state and logs user out', () async {
      final backend = _FakeBackend();
      final state = backend.newState();
      await state.login(_email, _password);
      expect(state.employee, isNotNull);

      await state.logout();

      expect(state.employee, isNull);
      expect(state.activeRequest, isNull);
      expect(state.draft.lastWorkingDay, isNull);
    });

    test('a network failure becomes a clear error', () async {
      final api = ApiClient(
        httpClient:
        MockClient((_) async => throw http.ClientException('offline')),
        baseUrl: 'http://test/api/v1',
      );

      await expectLater(
        api.get('/employee/cases'),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });

    test('a server error (500) is reported as a server error', () async {
      final api = ApiClient(
        httpClient: MockClient(
                (_) async => _json(500, _error('INTERNAL', 'Server error'))),
        baseUrl: 'http://test/api/v1',
      );

      await expectLater(
        api.get('/employee/cases'),
        throwsA(isA<ApiException>()
            .having((e) => e.isServerError, 'isServerError', true)),
      );
    });
  });
}