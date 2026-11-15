import 'dart:convert';

import 'package:e_clearance_mobile/core/auth/auth_repository.dart';
import 'package:e_clearance_mobile/core/auth/token_storage.dart';
import 'package:e_clearance_mobile/core/network/api_client.dart';
import 'package:e_clearance_mobile/core/network/api_exception.dart';
import 'package:e_clearance_mobile/features/student/data/student_repository.dart';
import 'package:e_clearance_mobile/features/student/models/student_api_models.dart';
import 'package:e_clearance_mobile/features/student/state/student_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Helpers: a fake in-memory server. No real network is used.
// ---------------------------------------------------------------------------
typedef Handler = Future<http.Response> Function(http.Request request);

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response errorResponse(int status, String code, String message) =>
    jsonResponse({
      'error': {'code': code, 'message': message, 'details': null},
    }, status);

int count(List<http.Request> calls, String method, String path) => calls
    .where((r) => r.method == method && r.url.path == '/api/v1$path')
    .length;

ApiClient newClient(Handler handler, List<http.Request> calls,
    {String? token}) {
  final api = ApiClient(
    httpClient: MockClient((req) {
      calls.add(req);
      return handler(req);
    }),
    baseUrl: 'http://test/api/v1',
  );
  api.authToken = token;
  return api;
}

/// In-memory token store so tests never touch the secure-storage plugin.
class FakeTokenStorage extends TokenStorage {
  String? token;

  @override
  Future<void> save(String value) async {
    token = value;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async {
    token = null;
  }
}

// ---------------------------------------------------------------------------
// Fixtures (fictional data shaped like the proposed contract)
// ---------------------------------------------------------------------------
const _uuid = '11111111-1111-1111-1111-111111111111';

Map<String, dynamic> dept(String code, String name, String status,
    {String applicability = 'REQUIRED'}) =>
    {
      'departmentCode': code,
      'displayName': name,
      'applicability': applicability,
      'status': status,
      'remarks': null,
      'updatedAt': null,
    };

List<Map<String, dynamic>> fiveDepartments({String library = 'PENDING'}) => [
  dept('LIBRARY', 'Library', library),
  dept('FEE_DUES', 'Fee & Dues Department', 'PENDING'),
  dept('STUDENT_SERVICE', 'Student Service Department', 'PENDING'),
  dept('LABORATORY', 'Laboratory (if required)', 'PENDING',
      applicability: 'UNDETERMINED'),
  dept('COORDINATION_OFFICE', 'Coordination Office', 'PENDING'),
];

Map<String, dynamic> summaryJson(
    {bool active = true, String ref = 'ECLR-STU-0001'}) =>
    {
      'id': _uuid,
      'requestReference': ref,
      'reason': 'degree completed',
      'isActive': active,
      'submittedAt': '2026-11-10T08:00:00.000Z',
      'closedAt': active ? null : '2026-11-12T08:00:00.000Z',
    };

Map<String, dynamic> requestJson({String ref = 'ECLR-STU-0001'}) => {
  ...summaryJson(ref: ref),
  'sapId': '00012345',
  'studentName': 'Fictional Student',
  'registrationNumber': 'RIU-2022-CS-0001',
  'fatherName': 'Fictional Father',
  'program': 'BSSE',
  'semester': '8',
  'departments': fiveDepartments(),
};

Map<String, dynamic> dashboardJson(
    {bool active = false, String library = 'PENDING'}) =>
    {
      'data': {
        'profile': {'sapId': '00012345', 'studentName': 'Fictional Student'},
        'activeRequest': active ? summaryJson() : null,
        'departments': active ? fiveDepartments(library: library) : [],
        'progress': null,
        'history': {'closedRequestCount': 0, 'latestClosedRequest': null},
      },
    };

StudentState newState(Handler handler, List<http.Request> calls) {
  final state = StudentState(
    repository: StudentRepository(newClient(handler, calls, token: 'tok')),
    email: 'student@university.example',
  );
  addTearDown(state.dispose);
  return state;
}

void fillDraft(StudentState s,
    {ClearanceReason? reason = ClearanceReason.degreeCompleted}) {
  s.draft.registrationNumber = ' RIU-2022-CS-0001 ';
  s.draft.fatherName = 'Fictional Father';
  s.draft.program = 'BSSE';
  s.draft.semester = '8';
  s.draft.reason = reason;
}

Matcher apiError({int? status, String? code}) => throwsA(
  isA<ApiException>()
      .having((e) => e.statusCode, 'statusCode', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  // -------------------------------------------------------------------------
  group('Student models', () {
    test('empty dashboard parses with no active request', () {
      final dto = StudentDashboardDto.fromJson(dashboardJson()['data']);
      expect(dto.activeRequest, isNull);
      expect(dto.departments, isEmpty);
      expect(dto.closedRequestCount, 0);
      expect(dto.profile!.sapId, '00012345');
    });

    test('unknown department status does not crash', () {
      final d = DepartmentDto.fromJson(
          {'departmentCode': 'LIBRARY', 'status': 'SOMETHING_NEW'});
      expect(d.status, DepartmentApiStatus.unknown);
      expect(d.displayName, 'LIBRARY'); // falls back to the code
    });

    test('NOT_REQUIRED is not CLEARED', () {
      final d = DepartmentDto.fromJson({
        'departmentCode': 'LABORATORY',
        'status': 'NOT_REQUIRED',
        'applicability': 'NOT_REQUIRED',
      });
      expect(d.status, DepartmentApiStatus.notRequired);
      expect(d.status, isNot(DepartmentApiStatus.cleared));
    });

    test('a request without an id is rejected as unexpected', () {
      expect(
            () => StudentRequestSummaryDto.fromJson(
            {'requestReference': 'X', 'reason': 'r', 'isActive': true}),
        throwsA(isA<ApiException>()),
      );
    });

    test('a non-object profile is rejected as unexpected', () {
      expect(() => StudentProfileDto.fromJson('nope'),
          throwsA(isA<ApiException>()));
    });
  });

  // -------------------------------------------------------------------------
  group('StudentRepository', () {
    test('fetchProfile calls GET /student/profile with the Bearer token',
            () async {
          final calls = <http.Request>[];
          final api = newClient((req) async {
            return jsonResponse({
              'data': {'sapId': '00012345', 'studentName': 'Fictional Student'}
            });
          }, calls, token: 'tok');

          final p = await StudentRepository(api).fetchProfile();

          expect(p.studentName, 'Fictional Student');
          expect(calls.single.method, 'GET');
          expect(calls.single.url.path, '/api/v1/student/profile');
          expect(calls.single.headers['Authorization'], 'Bearer tok');
        });

    test('createRequest sends exactly the five approved fields, trimmed',
            () async {
          final calls = <http.Request>[];
          final api = newClient(
                  (req) async => jsonResponse({'data': requestJson()}, 201), calls,
              token: 'tok');

          final created = await StudentRepository(api).createRequest(
            registrationNumber: ' RIU-1 ',
            fatherName: 'Father',
            program: 'BSSE',
            semester: '8',
            reason: StudentReasons.degreeCompleted,
          );

          final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
          expect(body.keys.toSet(), {
            'registrationNumber',
            'fatherName',
            'program',
            'semester',
            'reason',
          });
          expect(body['registrationNumber'], 'RIU-1');
          expect(body['reason'], 'degree completed');
          expect(body.containsKey('sapId'), isFalse);
          expect(created.summary.id, _uuid);
          expect(created.summary.requestReference, 'ECLR-STU-0001');
        });

    test('listRequests accepts an empty list', () async {
      final calls = <http.Request>[];
      final api = newClient((req) async => jsonResponse({'data': []}), calls);
      expect(await StudentRepository(api).listRequests(), isEmpty);
    });

    test('listRequests rejects a non-list reply as unexpected', () async {
      final calls = <http.Request>[];
      final api = newClient(
              (req) async => jsonResponse({'data': {'oops': 1}}), calls);
      await expectLater(StudentRepository(api).listRequests(),
          throwsA(isA<ApiException>()));
    });

    test('fetchRequest encodes the id so it cannot change the path', () async {
      final calls = <http.Request>[];
      final api = newClient(
              (req) async => jsonResponse({'data': requestJson()}), calls);
      await StudentRepository(api).fetchRequest('a/b');
      expect(calls.single.url.path.endsWith('a%2Fb'), isTrue);
    });

    test('401 triggers the session-expired callback once', () async {
      final calls = <http.Request>[];
      var expired = 0;
      final api = newClient(
              (req) async => errorResponse(401, 'UNAUTHORIZED', 'No'), calls,
          token: 'tok');
      api.onUnauthorized = () => expired++;

      await expectLater(StudentRepository(api).fetchProfile(),
          apiError(status: 401, code: 'UNAUTHORIZED'));
      expect(expired, 1);
    });

    test('403, 404, 409 and 500 keep their status and code', () async {
      for (final c in [
        [403, 'FORBIDDEN'],
        [404, 'NOT_FOUND'],
        [409, 'ACTIVE_REQUEST_EXISTS'],
        [500, 'INTERNAL_SERVER_ERROR'],
      ]) {
        final api = newClient(
                (req) async => errorResponse(c[0] as int, c[1] as String, 'x'),
            <http.Request>[],
            token: 'tok');
        await expectLater(StudentRepository(api).fetchProfile(),
            apiError(status: c[0] as int, code: c[1] as String));
      }
    });

    test('a network failure becomes a retryable network error', () async {
      final api = newClient((req) async {
        throw http.ClientException('offline');
      }, <http.Request>[]);
      await expectLater(
        StudentRepository(api).fetchDashboard(),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('Auth role handling', () {
    Map<String, dynamic> loginJson(String role) => {
      // Top level, NOT wrapped in "data".
      'accessToken': 'abc',
      'tokenType': 'Bearer',
      'expiresIn': 900,
      'user': {
        'id': 'u1',
        'email': 'person@university.example',
        'fullName': 'Person',
        'role': role,
      },
    };

    test('student login sends email and password only and saves the token',
            () async {
          final calls = <http.Request>[];
          final storage = FakeTokenStorage();
          final api =
          newClient((req) async => jsonResponse(loginJson('STUDENT')), calls);
          final repo = AuthRepository(apiClient: api, tokenStorage: storage);

          final user = await repo.login(
            email: ' person@university.example ',
            password: 'secret',
            expectedRole: 'STUDENT',
          );

          final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
          expect(body.keys.toSet(), {'email', 'password'});
          expect(body['email'], 'person@university.example');
          expect(user.role, 'STUDENT');
          expect(storage.token, 'abc');
          expect(api.authToken, 'abc');
        });

    test('a non-student account on the student path is rejected, nothing saved',
            () async {
          final storage = FakeTokenStorage();
          final api = newClient((req) async => jsonResponse(loginJson('EMPLOYEE')),
              <http.Request>[]);
          final repo = AuthRepository(apiClient: api, tokenStorage: storage);

          await expectLater(
            repo.login(
                email: 'a@b.co', password: 'x', expectedRole: 'STUDENT'),
            throwsA(isA<ApiException>()
                .having((e) => e.isRoleMismatch, 'isRoleMismatch', true)
                .having((e) => e.statusCode, 'statusCode', 403)),
          );
          expect(storage.token, isNull);
          expect(api.authToken, isNull);
        });

    test('employee login still rejects a student account (no regression)',
            () async {
          final storage = FakeTokenStorage();
          final api = newClient((req) async => jsonResponse(loginJson('STUDENT')),
              <http.Request>[]);
          final repo = AuthRepository(apiClient: api, tokenStorage: storage);

          await expectLater(
            repo.login(email: 'a@b.co', password: 'x'),
            throwsA(isA<ApiException>()
                .having((e) => e.isRoleMismatch, 'isRoleMismatch', true)),
          );
          expect(storage.token, isNull);
        });

    test('a wrong password gives a clear message', () async {
      final api = newClient(
              (req) async => errorResponse(401, 'UNAUTHORIZED', 'bad'),
          <http.Request>[]);
      final repo =
      AuthRepository(apiClient: api, tokenStorage: FakeTokenStorage());

      await expectLater(
        repo.login(email: 'a@b.co', password: 'x', expectedRole: 'STUDENT'),
        throwsA(isA<ApiException>().having(
                (e) => e.message, 'message', 'Incorrect email or password.')),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('StudentState dashboard', () {
    test('no active request is a successful empty state', () async {
      final state = newState(
              (req) async => jsonResponse(dashboardJson()), <http.Request>[]);
      await state.refreshDashboard();
      expect(state.dashboardLoad, LoadState.ready);
      expect(state.hasActiveRequest, isFalse);
      expect(state.currentRequest, isNull);
    });

    test('active request shows all five departments from the server',
            () async {
          final state = newState(
                  (req) async => jsonResponse(dashboardJson(active: true, library: 'CLEARED')),
              <http.Request>[]);
          await state.refreshDashboard();

          expect(state.hasActiveRequest, isTrue);
          final r = state.currentRequest!;
          expect(r.referenceNumber, 'ECLR-STU-0001');
          expect(r.departments, hasLength(5));
          expect(r.departments.first.status, DepartmentStatus.cleared);
          expect(r.departments.map((d) => d.name), isNot(contains('Examination')));
        });

    test('a server error is an error state, never "no active request"',
            () async {
          final state = newState(
                  (req) async => errorResponse(500, 'INTERNAL_SERVER_ERROR', 'boom'),
              <http.Request>[]);
          await state.refreshDashboard();
          expect(state.dashboardLoad, LoadState.error);
          expect(state.dashboardError, contains('Server error'));
        });

    test('a network failure is an error state with a retryable message',
            () async {
          final state = newState((req) async {
            throw http.ClientException('offline');
          }, <http.Request>[]);
          await state.refreshDashboard();
          expect(state.dashboardLoad, LoadState.error);
          expect(state.dashboardError, contains('Cannot reach the server'));
        });

    test('403 shows an access message', () async {
      final state = newState(
              (req) async => errorResponse(403, 'FORBIDDEN', 'no'),
          <http.Request>[]);
      await state.refreshDashboard();
      expect(state.dashboardLoad, LoadState.error);
      expect(state.dashboardError, contains('do not have access'));
    });

    test('a missing profile (404) gives a safe not-found message', () async {
      final state = newState(
              (req) async => errorResponse(404, 'NOT_FOUND', 'none'),
          <http.Request>[]);
      await state.loadProfile();
      expect(state.profile, isNull);
      expect(state.profileError, contains('not found'));
    });

    test('malformed JSON shape is a controlled error, not a crash', () async {
      final state = newState(
              (req) async => jsonResponse({'data': 'not an object'}),
          <http.Request>[]);
      await state.refreshDashboard();
      expect(state.dashboardLoad, LoadState.error);
      expect(state.dashboardError, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  group('StudentState submit', () {
    test('success uses the server reference and activates the request',
            () async {
          final calls = <http.Request>[];
          final state = newState(
                  (req) async => jsonResponse(
                  {'data': requestJson(ref: 'ECLR-STU-0007')}, 201),
              calls);
          fillDraft(state);

          final outcome = await state.submitRequest();

          expect(outcome, SubmitOutcome.success);
          expect(state.lastSubmission!.referenceNumber, 'ECLR-STU-0007');
          expect(state.hasActiveRequest, isTrue);
          expect(state.currentRequest!.requestId, _uuid);
          final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
          expect(body['reason'], 'degree completed');
          expect(body['registrationNumber'], 'RIU-2022-CS-0001');
        });

    test('nothing is sent when no reason is selected', () async {
      final calls = <http.Request>[];
      final state = newState(
              (req) async => jsonResponse({'data': requestJson()}, 201), calls);
      fillDraft(state, reason: null);

      expect(await state.submitRequest(), SubmitOutcome.failed);
      expect(calls, isEmpty);
      expect(state.submitError, isNotNull);
    });

    test('two quick taps send only one request', () async {
      final calls = <http.Request>[];
      final state = newState((req) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return jsonResponse({'data': requestJson()}, 201);
      }, calls);
      fillDraft(state);

      final results =
      await Future.wait([state.submitRequest(), state.submitRequest()]);

      expect(count(calls, 'POST', '/student/requests'), 1);
      expect(results, contains(SubmitOutcome.success));
      expect(results, contains(SubmitOutcome.failed));
    });

    test('409 ACTIVE_REQUEST_EXISTS refreshes and is not reported as success',
            () async {
          final calls = <http.Request>[];
          final state = newState((req) async {
            if (req.method == 'POST') {
              return errorResponse(409, 'ACTIVE_REQUEST_EXISTS', 'exists');
            }
            return jsonResponse(dashboardJson(active: true));
          }, calls);
          fillDraft(state);

          final outcome = await state.submitRequest();

          expect(outcome, SubmitOutcome.conflict);
          expect(state.lastSubmission, isNull);
          expect(state.hasActiveRequest, isTrue);
          expect(count(calls, 'POST', '/student/requests'), 1);
          expect(count(calls, 'GET', '/student/dashboard'), 1);
        });

    test('422 shows a safe validation message and keeps the draft', () async {
      final state = newState(
              (req) async => errorResponse(422, 'VALIDATION_ERROR', 'bad'),
          <http.Request>[]);
      fillDraft(state);

      expect(await state.submitRequest(), SubmitOutcome.failed);
      expect(state.submitError, contains('not valid'));
      expect(state.draft.program, 'BSSE');
    });

    test('500 fails without forcing a refresh before the next try', () async {
      final calls = <http.Request>[];
      final state = newState(
              (req) async => errorResponse(500, 'INTERNAL_SERVER_ERROR', 'boom'),
          calls);
      fillDraft(state);

      await state.submitRequest();
      await state.submitRequest();

      expect(count(calls, 'POST', '/student/requests'), 2);
      expect(count(calls, 'GET', '/student/dashboard'), 0);
    });

    test('after a timeout the dashboard is refreshed before another submit',
            () async {
          final calls = <http.Request>[];
          var posts = 0;
          final state = newState((req) async {
            if (req.method == 'POST') {
              posts++;
              throw http.ClientException('timeout');
            }
            // The first request actually reached the server.
            return jsonResponse(dashboardJson(active: true));
          }, calls);
          fillDraft(state);

          expect(await state.submitRequest(), SubmitOutcome.failed);
          expect(state.submitError, contains('may not have been sent'));

          final second = await state.submitRequest();

          expect(second, SubmitOutcome.conflict);
          expect(posts, 1); // no duplicate POST
          expect(count(calls, 'GET', '/student/dashboard'), 1);
        });

    test('after a timeout with no request on the server, submit proceeds',
            () async {
          final calls = <http.Request>[];
          var posts = 0;
          final state = newState((req) async {
            if (req.method == 'POST') {
              posts++;
              if (posts == 1) throw http.ClientException('timeout');
              return jsonResponse({'data': requestJson()}, 201);
            }
            return jsonResponse(dashboardJson()); // nothing was created
          }, calls);
          fillDraft(state);

          expect(await state.submitRequest(), SubmitOutcome.failed);
          expect(await state.submitRequest(), SubmitOutcome.success);
          expect(posts, 2);
          expect(count(calls, 'GET', '/student/dashboard'), 1);
        });
  });
}