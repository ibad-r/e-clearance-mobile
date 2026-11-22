import 'dart:async';
import 'dart:convert';

import 'package:e_clearance_mobile/core/app_state.dart';
import 'package:e_clearance_mobile/core/auth/auth_repository.dart';
import 'package:e_clearance_mobile/core/network/api_exception.dart';
import 'package:e_clearance_mobile/core/routes.dart';
import 'package:e_clearance_mobile/core/theme/app_theme.dart';
import 'package:e_clearance_mobile/features/student/models/student_api_models.dart';
import 'package:e_clearance_mobile/features/student/screens/student_profile_screen.dart';
import 'package:e_clearance_mobile/features/student/screens/student_request_screen.dart';
import 'package:e_clearance_mobile/features/student/state/student_state.dart';
import 'package:e_clearance_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'student_api_test.dart' as fixtures;

final _profile = {
  ...fixtures.profileJson(),
  'sapId': '00a-opaque/SAP',
  'registrationNumber': '  arbitrary registration  ',
  'fatherName': '  Fictional Father  ',
  'program': '  BSSE  ',
  'semester': '  final  ',
};

Widget studentScreen(StudentState state, Widget child) =>
    ChangeNotifierProvider<StudentState>.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('Confirmed Student profile contract', () {
    test('all six fields retain opaque identifiers and exact stored text', () {
      final dto = StudentProfileDto.fromJson(_profile);
      expect(dto.sapId, _profile['sapId']);
      expect(dto.registrationNumber, _profile['registrationNumber']);
      expect(dto.fatherName, _profile['fatherName']);
      expect(dto.program, _profile['program']);
      expect(dto.semester, _profile['semester']);
      expect(dto.studentName, _profile['studentName']);
    });

    test(
      'missing, null, blank and wrongly typed profile fields fail safely',
      () {
        for (final key in _profile.keys) {
          for (final invalid in [null, '', '   ', 42]) {
            expect(
              () => StudentProfileDto.fromJson({..._profile, key: invalid}),
              throwsA(isA<ApiException>()),
              reason: '$key = $invalid',
            );
          }
          final missing = {..._profile}..remove(key);
          expect(
            () => StudentProfileDto.fromJson(missing),
            throwsA(isA<ApiException>()),
          );
        }
      },
    );

    test(
      'profile failure clears stale details, then retry loads all fields',
      () async {
        var fail = false;
        final state = fixtures.newState(
          (_) async => fail
              ? fixtures.errorResponse(
                  404,
                  'STUDENT_PROFILE_NOT_FOUND',
                  'missing',
                )
              : fixtures.jsonResponse({'data': _profile}),
          [],
        );
        await state.loadProfile();
        expect(state.profileLoad, LoadState.ready);
        expect(
          state.profile?.registrationNumber,
          _profile['registrationNumber'],
        );
        expect(state.profile?.email, 'student@university.example');
        fail = true;
        await state.loadProfile();
        expect(state.profileLoad, LoadState.error);
        expect(state.profile, isNull);
        expect(state.profileError, contains('not found'));
        fail = false;
        await state.loadProfile();
        expect(state.hasVerifiedProfile, isTrue);
        expect(state.profileError, isNull);
      },
    );

    test('submission is blocked until the profile is verified', () async {
      final calls = <dynamic>[];
      final state = fixtures.newState((request) async {
        calls.add(request);
        return fixtures.jsonResponse({'data': fixtures.requestJson()}, 201);
      }, []);
      state.draft.reason = ClearanceReason.degreeCompleted;
      expect(await state.submitRequest(), SubmitOutcome.failed);
      expect(calls, isEmpty);
      expect(state.submitError, contains('verified student profile'));
    });

    test('dashboard cannot replace an independently fetched profile', () async {
      final state = fixtures.newState(
        (request) async => fixtures.jsonResponse(
          request.url.path.endsWith('/profile')
              ? {'data': _profile}
              : fixtures.dashboardJson(),
        ),
        [],
      );
      await state.loadProfile();
      final verified = state.profile;
      await state.refreshDashboard();
      expect(state.profile, same(verified));
    });

    test(
      'profile mismatch blocks resubmission until retry and review',
      () async {
        var posts = 0;
        final state = fixtures.newState((request) async {
          if (request.method == 'POST') {
            posts++;
            return fixtures.errorResponse(422, 'PROFILE_MISMATCH', 'changed');
          }
          return fixtures.jsonResponse({'data': _profile});
        }, []);
        await state.loadProfile();
        state.draft.reason = ClearanceReason.degreeCompleted;
        expect(await state.submitRequest(), SubmitOutcome.failed);
        expect(state.profile, isNull);
        expect(state.profileError, contains('Reload your profile'));
        expect(await state.submitRequest(), SubmitOutcome.failed);
        expect(posts, 1);
        await state.loadProfile();
        expect(state.hasVerifiedProfile, isTrue);
        expect(state.draft.reason, ClearanceReason.degreeCompleted);
      },
    );

    test(
      'a refreshed profile cannot be submitted using an older review',
      () async {
        var posts = 0;
        final state = fixtures.newState((request) async {
          if (request.method == 'POST') posts++;
          return fixtures.jsonResponse({'data': _profile});
        }, []);
        await state.loadProfile();
        final reviewed = state.profile;
        await state.loadProfile();
        state.draft.reason = ClearanceReason.degreeCompleted;
        expect(
          await state.submitRequest(reviewedProfile: reviewed),
          SubmitOutcome.failed,
        );
        expect(posts, 0);
        expect(state.submitError, contains('review again'));
      },
    );
  });

  testWidgets('late profile autofills locked form; only reason is selected', (
    tester,
  ) async {
    final reply = Completer<void>();
    final state = fixtures.newState((_) async {
      await reply.future;
      return fixtures.jsonResponse({'data': _profile});
    }, []);
    var reviewed = false;
    final pending = state.loadProfile();
    await tester.pumpWidget(
      studentScreen(
        state,
        StudentRequestScreen(onReview: () => reviewed = true),
      ),
    );
    expect(find.text('Loading student profile…'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Review Request'),
          )
          .onPressed,
      isNull,
    );
    reply.complete();
    await pending;
    await tester.pumpAndSettle();
    for (final value in _profile.values) {
      expect(find.text(value), findsOneWidget);
    }
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(6));
    await tester.tap(find.text('Review Request'));
    await tester.pumpAndSettle();
    expect(reviewed, isFalse);
    expect(find.text('Select a clearance reason.'), findsOneWidget);
    await tester.ensureVisible(find.text('Degree Completed'));
    await tester.tap(find.text('Degree Completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Request'));
    await tester.pumpAndSettle();
    expect(reviewed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile settings show error, retry, actual details and account actions',
    (tester) async {
      var fail = true;
      final state = fixtures.newState(
        (_) async => fail
            ? fixtures.errorResponse(
                404,
                'STUDENT_PROFILE_NOT_FOUND',
                'missing',
              )
            : fixtures.jsonResponse({'data': _profile}),
        [],
      );
      await state.loadProfile();
      await tester.pumpWidget(
        studentScreen(state, const StudentProfileScreen()),
      );
      expect(find.textContaining('profile was not found'), findsOneWidget);
      expect(find.text('Retry profile'), findsOneWidget);
      expect(find.text('Dark'), findsNothing);
      expect(find.text('System Default'), findsNothing);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Switch Access Type'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry profile'));
      await tester.pumpAndSettle();
      expect(find.text(_profile['sapId']!), findsOneWidget);
      expect(find.text(_profile['registrationNumber']!), findsOneWidget);
      expect(find.text(_profile['program']!), findsOneWidget);
      expect(find.text('Retry profile'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SAP login, profile, review, submit and API read-back use one session',
    (tester) async {
      final storage = fixtures.FakeTokenStorage();
      final calls = <dynamic>[];
      var created = false;
      final api = fixtures.newClient((request) async {
        calls.add(request);
        final path = request.url.path;
        if (path.endsWith('/auth/login')) {
          expect(jsonDecode(request.body), {
            'identifier': _profile['sapId'],
            'password': ' existing password ',
          });
          return fixtures.jsonResponse({
            'accessToken': 'student-token',
            'tokenType': 'Bearer',
            'expiresIn': 900,
            'user': {
              'id': 'user-1',
              'email': 'real@account.example',
              'fullName': _profile['studentName'],
              'role': 'STUDENT',
            },
          });
        }
        expect(request.headers['Authorization'], 'Bearer student-token');
        if (path.endsWith('/student/profile')) {
          return fixtures.jsonResponse({'data': _profile});
        }
        if (path.endsWith('/student/dashboard')) {
          return fixtures.jsonResponse(fixtures.dashboardJson(active: created));
        }
        if (request.method == 'POST' && path.endsWith('/student/requests')) {
          expect(jsonDecode(request.body), {
            'registrationNumber': _profile['registrationNumber'],
            'fatherName': _profile['fatherName'],
            'program': _profile['program'],
            'semester': _profile['semester'],
            'reason': 'degree completed',
          });
          created = true;
          return fixtures.jsonResponse({
            'data': {...fixtures.requestJson(), ..._profile},
          }, 201);
        }
        if (path.contains('/student/requests/')) {
          expect(created, isTrue);
          return fixtures.jsonResponse({
            'data': {...fixtures.requestJson(), ..._profile},
          });
        }
        fail('Unexpected endpoint: $path');
      }, []);
      final app = AppState(
        apiClient: api,
        auth: AuthRepository(apiClient: api, tokenStorage: storage),
      );
      addTearDown(app.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: app,
          child: MaterialApp(
            theme: AppTheme.light,
            initialRoute: AppRoutes.studentLogin,
            routes: AppRoutes.table,
          ),
        ),
      );
      expect(find.text('Email or SAP ID'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        '  ${_profile['sapId']}  ',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        ' existing password ',
      );
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(storage.token, 'student-token');
      expect(find.text(_profile['studentName']!), findsOneWidget);
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();
      expect(find.text(_profile['registrationNumber']!), findsOneWidget);
      await tester.ensureVisible(find.text('Degree Completed'));
      await tester.tap(find.text('Degree Completed'));
      await tester.tap(find.text('Review Request'));
      await tester.pumpAndSettle();
      // Confirm the existing review screen and its actual button label.
      await tester.ensureVisible(find.text('Confirm and Submit'));
      await tester.tap(find.text('Confirm and Submit'));
      await tester.pumpAndSettle();
      expect(created, isTrue);
      final student = tester
          .element(find.byType(Scaffold).last)
          .read<StudentState>();
      await student.loadDetail();
      await tester.pumpAndSettle();
      expect(
        student.detail?.registrationNumber,
        _profile['registrationNumber'],
      );
      expect(student.detail?.sapId, _profile['sapId']);
      expect(
        calls.where((r) => r.url.path.endsWith('/student/profile')),
        hasLength(1),
      );
      expect(
        calls.where(
          (r) => r.method == 'POST' && r.url.path.endsWith('/student/requests'),
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'production app keeps light appearance under a dark system preference',
    (tester) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
