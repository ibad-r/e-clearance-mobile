import 'dart:convert';

import 'package:e_clearance_mobile/core/network/api_client.dart';
import 'package:e_clearance_mobile/core/network/api_exception.dart';
import 'package:e_clearance_mobile/features/student/data/student_repository.dart';
import 'package:e_clearance_mobile/features/student/models/student_api_models.dart';
import 'package:e_clearance_mobile/features/student/state/student_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Fictional data shaped like the confirmed Student contract (PR #35).
typedef Handler = Future<http.Response> Function(http.Request request);

const _uuid = '11111111-1111-1111-1111-111111111111';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _error(int status, String code, String message) => _json({
  'error': {'code': code, 'message': message, 'details': null},
}, status);

StudentState _newState(Handler handler, List<http.Request> calls) {
  final api = ApiClient(
    httpClient: MockClient((req) {
      calls.add(req);
      return handler(req);
    }),
    baseUrl: 'http://test/api/v1',
  )..authToken = 'tok';
  final state = StudentState(
    repository: StudentRepository(api),
    email: 'student@university.example',
  );
  addTearDown(state.dispose);
  return state;
}

Map<String, dynamic> _dept(
    String code,
    String name,
    String status, {
      String applicability = 'REQUIRED',
      String? remarks,
    }) => {
  'departmentCode': code,
  'displayName': name,
  'applicability': applicability,
  'status': status,
  'remarks': remarks,
  'updatedAt': null,
};

/// Library action required with a reason, Laboratory not yet determined,
/// Fee & Dues exempt, the rest cleared.
List<Map<String, dynamic>> _mixedDepartments() => [
  _dept(
    'LIBRARY',
    'Library',
    'ACTION_REQUIRED',
    remarks: 'Please return the borrowed book.',
  ),
  _dept(
    'FEE_DUES',
    'Fee & Dues Department',
    'NOT_REQUIRED',
    applicability: 'NOT_REQUIRED',
  ),
  _dept('STUDENT_SERVICE', 'Student Service Department', 'CLEARED'),
  _dept(
    'LABORATORY',
    'Laboratory (if required)',
    'PENDING',
    applicability: 'UNDETERMINED',
  ),
  _dept('COORDINATION_OFFICE', 'Coordination Office', 'CLEARED'),
];

/// Everything cleared, Laboratory explicitly exempt.
List<Map<String, dynamic>> _completedDepartments() => [
  _dept('LIBRARY', 'Library', 'CLEARED'),
  _dept('FEE_DUES', 'Fee & Dues Department', 'CLEARED'),
  _dept('STUDENT_SERVICE', 'Student Service Department', 'CLEARED'),
  _dept(
    'LABORATORY',
    'Laboratory (if required)',
    'NOT_REQUIRED',
    applicability: 'NOT_REQUIRED',
  ),
  _dept('COORDINATION_OFFICE', 'Coordination Office', 'CLEARED'),
];

Map<String, dynamic> _summary({
  bool active = true,
  String status = 'IN_PROGRESS',
}) => {
  'id': _uuid,
  'requestReference': 'ECLR-STU-0001',
  'reason': 'degree completed',
  'status': status,
  'isActive': active,
  'submittedAt': '2026-11-10T08:00:00.000Z',
  'closedAt': active ? null : '2026-11-10T08:00:01.000Z',
};

Map<String, dynamic> _request({
  bool active = true,
  String status = 'IN_PROGRESS',
  required List<Map<String, dynamic>> departments,
}) => {
  ..._summary(active: active, status: status),
  'sapId': '00012345',
  'studentName': 'Fictional Student',
  'registrationNumber': 'RIU-2022-CS-0001',
  'fatherName': 'Fictional Father',
  'program': 'BSSE',
  'semester': '8',
  'departments': departments,
};

Map<String, dynamic> _profile() => {
  'sapId': '00012345',
  'studentName': 'Fictional Student',
  'registrationNumber': 'RIU-2022-CS-0001',
  'fatherName': 'Fictional Father',
  'program': 'BSSE',
  'semester': '8',
};

Map<String, dynamic> _activeDashboard() => {
  'data': {
    'profile': _profile(),
    'activeRequest': _summary(),
    'departments': _mixedDepartments(),
    'progress': {
      'requiredCount': 3,
      'clearedRequiredCount': 2,
      'actionRequiredCount': 1,
      'notRequiredCount': 1,
      'undeterminedCount': 1,
    },
    'history': {'closedRequestCount': 0, 'latestClosedRequest': null},
  },
};

/// No active request, one completed request in history.
Map<String, dynamic> _closedDashboard() => {
  'data': {
    'profile': _profile(),
    'activeRequest': null,
    'departments': <Map<String, dynamic>>[],
    'progress': null,
    'history': {
      'closedRequestCount': 1,
      'latestClosedRequest': _summary(active: false, status: 'COMPLETED'),
    },
  },
};

void _fillDraft(StudentState s) {
  s.profile = StudentProfile.fromDto(StudentProfileDto.fromJson(_profile()));
  s.profileLoad = LoadState.ready;
  s.draft.reason = ClearanceReason.degreeCompleted;
}

DepartmentStatusItem _byCode(StudentRequestStatus r, String code) =>
    r.departments.firstWhere((d) => d.code == code);

void main() {
  group('Parent status and progress models', () {
    test('parent status values are parsed', () {
      expect(
        StudentRequestSummaryDto.fromJson(_summary()).status,
        RequestParentStatus.inProgress,
      );
      expect(
        StudentRequestSummaryDto.fromJson(
          _summary(active: false, status: 'COMPLETED'),
        ).status,
        RequestParentStatus.completed,
      );
      expect(
        StudentRequestSummaryDto.fromJson(
          _summary(active: false, status: 'CANCELLED'),
        ).status,
        RequestParentStatus.cancelled,
      );
    });

    test('an unknown parent status does not crash', () {
      final s = StudentRequestSummaryDto.fromJson(
        _summary(status: 'SOMETHING_NEW'),
      );
      expect(s.status, RequestParentStatus.unknown);
    });

    test('progress counts are parsed from the dashboard', () {
      final dto = StudentDashboardDto.fromJson(_activeDashboard()['data']);
      expect(dto.progress!.requiredCount, 3);
      expect(dto.progress!.clearedRequiredCount, 2);
      expect(dto.progress!.actionRequiredCount, 1);
      expect(dto.progress!.notRequiredCount, 1);
      expect(dto.progress!.undeterminedCount, 1);
    });

    test('progress with a missing count is rejected as unexpected', () {
      expect(
            () => StudentProgressDto.fromJson({'requiredCount': 1}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Department display rules', () {
    test('UNDETERMINED is undetermined and not exempt', () {
      final d = DepartmentDto.fromJson(
        _dept('LABORATORY', 'Laboratory', 'PENDING',
            applicability: 'UNDETERMINED'),
      );
      expect(d.isUndetermined, isTrue);
      expect(d.isExempt, isFalse);
    });

    test('NOT_REQUIRED is exempt, not undetermined', () {
      final d = DepartmentDto.fromJson(
        _dept('LABORATORY', 'Laboratory', 'NOT_REQUIRED',
            applicability: 'NOT_REQUIRED'),
      );
      expect(d.isExempt, isTrue);
      expect(d.isUndetermined, isFalse);
    });

    test('visibleReason is null for null or blank remarks', () {
      expect(
        DepartmentDto.fromJson(_dept('LIBRARY', 'Library', 'CLEARED'))
            .visibleReason,
        isNull,
      );
      expect(
        DepartmentDto.fromJson(
          _dept('LIBRARY', 'Library', 'CLEARED', remarks: '   '),
        ).visibleReason,
        isNull,
      );
      expect(
        DepartmentDto.fromJson(
          _dept('LIBRARY', 'Library', 'ACTION_REQUIRED', remarks: ' Return book '),
        ).visibleReason,
        'Return book',
      );
    });
  });

  group('StudentState saved results', () {
    test('dashboard maps UNDETERMINED, NOT_REQUIRED and reasons', () async {
      final state = _newState(
            (req) async => _json(_activeDashboard()),
        <http.Request>[],
      );
      await state.refreshDashboard();

      final r = state.currentRequest!;
      expect(r.departments, hasLength(5));
      // Laboratory is not decided yet: never cleared, never exempt.
      expect(_byCode(r, 'LABORATORY').status, DepartmentStatus.undetermined);
      // Fee & Dues is an explicit exemption, separate from cleared.
      expect(_byCode(r, 'FEE_DUES').status, DepartmentStatus.notRequired);
      expect(_byCode(r, 'LIBRARY').status, DepartmentStatus.actionRequired);
      // The approved reason comes through. Other departments have none.
      expect(_byCode(r, 'LIBRARY').reason, 'Please return the borrowed book.');
      expect(_byCode(r, 'STUDENT_SERVICE').reason, isNull);
    });

    test('progress counts are stored for an active request', () async {
      final state = _newState(
            (req) async => _json(_activeDashboard()),
        <http.Request>[],
      );
      await state.refreshDashboard();

      expect(state.progress!.requiredCount, 3);
      expect(state.progress!.clearedRequiredCount, 2);
      expect(state.progress!.undeterminedCount, 1);
    });

    test('the active request is preferred over a closed one', () async {
      final state = _newState(
            (req) async => _json(_activeDashboard()),
        <http.Request>[],
      );
      await state.refreshDashboard();

      expect(state.displayRequest!.requestId, _uuid);
      expect(state.displayRequest, same(state.currentRequest));
    });

    test('a completed request loads its saved results by UUID', () async {
      final calls = <http.Request>[];
      final state = _newState((req) async {
        if (req.url.path.endsWith('/student/dashboard')) {
          return _json(_closedDashboard());
        }
        if (req.url.path.endsWith('/student/requests/$_uuid')) {
          return _json({
            'data': _request(
              active: false,
              status: 'COMPLETED',
              departments: _completedDepartments(),
            ),
          });
        }
        return _error(404, 'NOT_FOUND', 'none');
      }, calls);

      await state.refreshDashboard();

      expect(state.dashboardLoad, LoadState.ready);
      expect(state.hasActiveRequest, isFalse);
      expect(state.currentRequest, isNull);
      expect(state.closedRequestCount, 1);
      // The latest closed request still shows all five saved departments.
      final r = state.displayRequest!;
      expect(r.requestId, _uuid);
      expect(r.overallStatus, 'Completed');
      expect(r.departments, hasLength(5));
      expect(_byCode(r, 'LABORATORY').status, DepartmentStatus.notRequired);
      expect(_byCode(r, 'LIBRARY').status, DepartmentStatus.cleared);
    });

    test('a failed closed-request load does not break the dashboard', () async {
      final state = _newState((req) async {
        if (req.url.path.endsWith('/student/dashboard')) {
          return _json(_closedDashboard());
        }
        return _error(500, 'INTERNAL_SERVER_ERROR', 'boom');
      }, <http.Request>[]);

      await state.refreshDashboard();

      expect(state.dashboardLoad, LoadState.ready);
      expect(state.latestClosed, isNotNull);
      expect(state.latestClosedStatus, isNull);
    });

    test('a request completed at submit is kept and not shown as active',
            () async {
          final state = _newState((req) async {
            if (req.method == 'POST') {
              return _json({
                'data': _request(
                  active: false,
                  status: 'COMPLETED',
                  departments: _completedDepartments(),
                ),
              }, 201);
            }
            return _error(404, 'NOT_FOUND', 'none');
          }, <http.Request>[]);
          _fillDraft(state);

          expect(await state.submitRequest(), SubmitOutcome.success);

          expect(state.hasActiveRequest, isFalse);
          expect(state.currentRequest, isNull);
          expect(state.lastSubmission!.completed, isTrue);
          expect(state.lastSubmission!.status, 'Completed');
          // The returned UUID and results are preserved.
          expect(state.displayRequest!.requestId, _uuid);
          expect(state.displayRequest!.departments, hasLength(5));
        });

    test('details can be opened right after an immediate completion',
            () async {
          final calls = <http.Request>[];
          final state = _newState((req) async {
            if (req.method == 'POST') {
              return _json({
                'data': _request(
                  active: false,
                  status: 'COMPLETED',
                  departments: _completedDepartments(),
                ),
              }, 201);
            }
            if (req.url.path.endsWith('/student/requests/$_uuid')) {
              return _json({
                'data': _request(
                  active: false,
                  status: 'COMPLETED',
                  departments: _completedDepartments(),
                ),
              });
            }
            return _error(404, 'NOT_FOUND', 'none');
          }, calls);
          _fillDraft(state);

          await state.submitRequest();
          await state.loadDetail();

          expect(state.detailLoad, LoadState.ready);
          expect(state.detail!.overallStatus, 'Completed');
          expect(state.detail!.departments, hasLength(5));
        });

    test('503 on submit shows a clear message and keeps the draft', () async {
      final state = _newState(
            (req) async => _error(
          503,
          'REQUEST_CREATION_UNAVAILABLE',
          'unavailable',
        ),
        <http.Request>[],
      );
      _fillDraft(state);

      expect(await state.submitRequest(), SubmitOutcome.failed);

      expect(state.submitError, contains('temporarily unavailable'));
      expect(state.draft.reason, ClearanceReason.degreeCompleted);
    });
  });
}