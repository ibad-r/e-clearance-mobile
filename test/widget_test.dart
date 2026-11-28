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

Map<String, dynamic> _sequentialCaseJson({
  int? blockedAt = 2,
  bool completed = false,
  String? certificateId,
}) => {
  ..._caseJson(),
  'status': completed
      ? 'COMPLETED'
      : blockedAt == null
      ? 'IN_PROGRESS'
      : 'ACTION_REQUIRED',
  'stages': [
    for (var i = 14; i >= 1; i--)
      {
        'id': 'stage-$i',
        'departmentName': 'Department $i',
        'stepOrder': i,
        'isRequired': true,
        'status': switch (i) {
          1 => 'NOT_APPLICABLE',
          _ when completed => 'CLEARED',
          _ when i == blockedAt => 'ACTION_REQUIRED',
          _ when i < (blockedAt ?? 3) => 'CLEARED',
          3 when blockedAt == null => 'CHECKING',
          _ => 'PENDING',
        },
      },
  ],
  'approvals': [],
  'issues': [
    if (blockedAt != null && !completed)
      {
        'requestStageId': 'stage-$blockedAt',
        'reason': 'Return the equipment issued to you.',
        'status': 'OPEN',
      },
  ],
  'certificateId': certificateId,
  'progress': {'totalStages': 14},
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
  _FakeBackend({
    List<Map<String, dynamic>>? cases,
    this.completeOnSubmit = false,
  }) : cases = cases ?? [];

  final bool completeOnSubmit;

  final List<Map<String, dynamic>> cases;
  final List<http.Request> log = [];

  int count(String method, String path) =>
      log.where((r) => r.method == method && r.url.path.endsWith(path)).length;

  http.Request lastRequest(String method, String path) =>
      log.lastWhere((r) => r.method == method && r.url.path.endsWith(path));

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
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final created = {
        ..._sequentialCaseJson(completed: completeOnSubmit),
        ...body,
      };
      cases.add(created);
      return _json(201, {'data': created});
    }

    if (r.method == 'GET' && path.endsWith('/employee/cases')) {
      return _json(200, {'data': cases});
    }

    if (r.method == 'GET' && path.contains('/employee/cases/')) {
      final id = r.url.pathSegments.last;
      final saved = cases.where((item) => item['id'] == id).firstOrNull;
      if (saved != null) return _json(200, {'data': saved});
    }

    return _json(404, _error('NOT_FOUND', 'Not found'));
  }

  ApiClient newClient() =>
      ApiClient(httpClient: MockClient(handle), baseUrl: 'http://test/api/v1');

  AppState newState() {
    final api = newClient();
    return AppState(
      apiClient: api,
      auth: AuthRepository(apiClient: api, tokenStorage: _FakeTokenStorage()),
    );
  }
}

Widget _buildApp(AppState state, {String route = AppRoutes.login}) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: route,
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

    testWidgets('correct login opens the dashboard with the real profile', (
      tester,
    ) async {
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

  testWidgets('review submits the form and opens sequential progress', (
    tester,
  ) async {
    final backend = _FakeBackend();
    final state = backend.newState();
    await state.login(_email, _password);
    state.draft
      ..lastWorkingDay = DateTime(2026, 11, 10)
      ..reason = 'Contract Completion';

    await tester.pumpWidget(_buildApp(state, route: AppRoutes.newClearance));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Review & Submit'), findsOneWidget);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Submit Clearance'));
    await tester.pumpAndSettle();

    expect(find.text('Request submitted successfully'), findsOneWidget);
    await tester.tap(find.text('Track Clearance Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Clearance Progress'), findsOneWidget);
    expect(find.text('Stage 2 of 14 · Department 2'), findsOneWidget);
    expect(backend.count('POST', '/employee/cases'), 1);
  });

  testWidgets('department details refresh using saved backend results', (
    tester,
  ) async {
    final backend = _FakeBackend(cases: [_sequentialCaseJson()]);
    final state = backend.newState();
    await state.login(_email, _password);

    await tester.pumpWidget(_buildApp(state, route: AppRoutes.progress));
    await tester.pumpAndSettle();
    final viewIssue = find.text('View Issue');
    await tester.scrollUntilVisible(viewIssue, 250);
    await Scrollable.ensureVisible(tester.element(viewIssue), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(viewIssue);
    await tester.pumpAndSettle();
    expect(find.text('Department Details'), findsOneWidget);
    expect(find.text('Return the equipment issued to you.'), findsOneWidget);

    await tester.tap(find.text('Refresh Status'));
    await tester.pumpAndSettle();
    expect(find.text('Action Required'), findsOneWidget);

    backend.cases[0] = _sequentialCaseJson(blockedAt: null);
    await tester.tap(find.text('Refresh Status'));
    await tester.pumpAndSettle();
    expect(find.text('Cleared'), findsOneWidget);
    expect(find.text('Action Required'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Department 3'), 200);
    expect(find.text('Checking'), findsOneWidget);
    expect(backend.log.where((r) => r.method == 'POST'), hasLength(1));
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

      final sent =
          jsonDecode(backend.lastRequest('POST', '/employee/cases').body)
              as Map<String, dynamic>;
      expect(sent.keys.toSet(), {
        'lastWorkingDate',
        'reasonForLeaving',
        'employeeRemarks',
      });
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

      final sent =
          jsonDecode(backend.lastRequest('POST', '/employee/cases').body)
              as Map<String, dynamic>;
      expect(sent['employeeRemarks'], 'Handover done');
    });

    test(
      'a reason shorter than 3 characters is rejected before sending',
      () async {
        final backend = _FakeBackend();
        final api = backend.newClient()..authToken = _token;
        final repo = ApiClearanceRepository(apiClient: api);

        await expectLater(
          repo.submit(_draft(reason: 'ab')),
          throwsA(
            isA<ApiException>().having(
              (e) => e.isValidation,
              'isValidation',
              true,
            ),
          ),
        );
        expect(backend.count('POST', '/employee/cases'), 0);
      },
    );

    test(
      'a second tap on submit is ignored while the first is running',
      () async {
        final backend = _FakeBackend();
        final state = backend.newState();
        await state.login(_email, _password);

        state.draft
          ..lastWorkingDay = DateTime(2026, 11, 10)
          ..reason = 'Contract Completion';

        await Future.wait([state.submit(), state.submit()]);

        expect(backend.count('POST', '/employee/cases'), 1);
      },
    );

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
      expect(state.activeRequest!.status, 'ACTION_REQUIRED');
      expect(state.activeRequest!.steps, hasLength(14));
    });

    test('saved stages show where clearance paused and resumed', () async {
      final backend = _FakeBackend(cases: [_sequentialCaseJson()]);
      final state = backend.newState();
      await state.login(_email, _password);

      var saved = state.activeRequest!;
      expect(saved.steps, hasLength(14));
      expect(saved.steps.first.status, StepStatus.notApplicable);
      expect(saved.currentStep!.department, 'Department 2');
      expect(saved.currentStep!.status, StepStatus.outstanding);
      expect(
        saved.openIssueFor(saved.currentStep!)!.reason,
        contains('equipment'),
      );
      expect(
        saved.steps.skip(2).every((s) => s.status == StepStatus.locked),
        isTrue,
      );
      expect(saved.evaluatedCount, 1);
      expect(saved.availableCertificateId, isNull);

      backend.cases[0] = _sequentialCaseJson(blockedAt: null);
      await state.refreshActiveCase();
      saved = state.activeRequest!;
      expect(saved.steps[1].status, StepStatus.cleared);
      expect(saved.currentStep!.department, 'Department 3');
      expect(saved.currentStep!.status, StepStatus.processing);
      expect(saved.steps[3].status, StepStatus.locked);
      expect(backend.count('POST', '/employee/cases'), 0);
    });

    test(
      'a certificate requires completed status and evaluated required stages',
      () {
        final inProgress = _sequentialCaseJson(certificateId: 'certificate-1');
        expect(
          ClearanceRequest.fromJson(inProgress).availableCertificateId,
          isNull,
        );
        final inconsistent = {...inProgress, 'status': 'COMPLETED'};
        expect(ClearanceRequest.fromJson(inconsistent).isCompleted, isFalse);

        final completed = _sequentialCaseJson(
          completed: true,
          certificateId: 'certificate-1',
        );
        final saved = ClearanceRequest.fromJson(completed);
        expect(saved.isCompleted, isTrue);
        expect(saved.progress, 1);
        expect(saved.availableCertificateId, 'certificate-1');
        expect(
          ClearanceRequest.fromJson({
            ...completed,
            'stages': [],
          }).availableCertificateId,
          isNull,
        );
        expect(
          ClearanceRequest.fromJson({
            ...completed,
            'certificateId': null,
          }).availableCertificateId,
          isNull,
        );
      },
    );

    test(
      'a lost submit reply recovers a case completed on the server',
      () async {
        final backend = _FakeBackend(completeOnSubmit: true);
        var dropNextReply = true;
        final api = ApiClient(
          httpClient: MockClient((r) async {
            if (dropNextReply &&
                r.method == 'POST' &&
                r.url.path.endsWith('/employee/cases')) {
              dropNextReply = false;
              // The server saved the case, but the reply never arrived.
              await backend.handle(r);
              throw http.ClientException('connection lost');
            }
            return backend.handle(r);
          }),
          baseUrl: 'http://test/api/v1',
        );
        final state = AppState(
          apiClient: api,
          auth: AuthRepository(
            apiClient: api,
            tokenStorage: _FakeTokenStorage(),
          ),
        );
        await state.login(_email, _password);

        state.draft
          ..lastWorkingDay = DateTime(2026, 11, 10)
          ..reason = 'Contract Completion';

        await expectLater(
          state.submit(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.isNetworkError,
              'isNetworkError',
              true,
            ),
          ),
        );
        expect(state.draft.reason, 'Contract Completion');

        await state.submit();

        expect(state.activeRequest!.isCompleted, isTrue);
        expect(state.draft.reason, isNull);
        expect(backend.count('POST', '/employee/cases'), 1);
      },
    );

    test('stages are sorted and show the backend department names', () async {
      final backend = _FakeBackend(cases: [_caseJson()]);
      final api = backend.newClient()..authToken = _token;
      final repo = ApiClearanceRepository(apiClient: api);

      final cases = await repo.listCases();

      expect(cases, hasLength(1));
      expect(cases.first.steps.map((s) => s.department).toList(), [
        'Test Finance',
        'Test Library',
      ]);
      expect(cases.first.steps.first.status, StepStatus.locked);
      expect(cases.first.totalStages, 2);
      expect(cases.first.approvals.first.status, 'WAITING');
    });

    test('409 ACTIVE_CASE_EXISTS is reported clearly', () async {
      final api = ApiClient(
        httpClient: MockClient(
          (_) async => _json(
            409,
            _error(
              'ACTIVE_CASE_EXISTS',
              'You already have an active clearance request.',
            ),
          ),
        ),
        baseUrl: 'http://test/api/v1',
      )..authToken = _token;
      final repo = ApiClearanceRepository(apiClient: api);

      await expectLater(
        repo.submit(_draft()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isActiveCaseExists, 'isActiveCaseExists', true)
              .having(
                (e) => e.message,
                'message',
                'You already have an active clearance request.',
              ),
        ),
      );
    });

    test(
      'an expired token (401) triggers the session-expired callback',
      () async {
        final backend = _FakeBackend();
        var expired = false;
        final api = backend.newClient()
          ..authToken = 'old-token'
          ..onUnauthorized = () => expired = true;

        await expectLater(
          api.get('/employee/cases'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.isUnauthorized,
              'isUnauthorized',
              true,
            ),
          ),
        );
        expect(expired, isTrue);
      },
    );

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
        httpClient: MockClient(
          (_) async => throw http.ClientException('offline'),
        ),
        baseUrl: 'http://test/api/v1',
      );

      await expectLater(
        api.get('/employee/cases'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isNetworkError,
            'isNetworkError',
            true,
          ),
        ),
      );
    });

    test('a server error (500) is reported as a server error', () async {
      final api = ApiClient(
        httpClient: MockClient(
          (_) async => _json(500, _error('INTERNAL', 'Server error')),
        ),
        baseUrl: 'http://test/api/v1',
      );

      await expectLater(
        api.get('/employee/cases'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isServerError,
            'isServerError',
            true,
          ),
        ),
      );
    });
  });
}
