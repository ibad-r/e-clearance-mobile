import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../models/clearance_request.dart';
import '../data/clearance_repository.dart';
import '../data/profile_repository.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_user.dart';
import 'network/api_client.dart';
import 'network/api_exception.dart';

class AppState extends ChangeNotifier {
  AppState({
    ApiClient? apiClient,
    AuthRepository? auth,
    ProfileRepository? profile,
    ClearanceRepository? clearance,
  }) : _api = apiClient ?? ApiClient() {
    _auth = auth ?? AuthRepository(apiClient: _api);
    _profile = profile ?? ProfileRepository(apiClient: _api);
    _clearance = clearance ?? ApiClearanceRepository(apiClient: _api);
    _api.onUnauthorized = _handleSessionExpired;
  }

  final ApiClient _api;
  late final AuthRepository _auth;
  late final ProfileRepository _profile;
  late final ClearanceRepository _clearance;

  /// Shared HTTP client. The Student module reuses it, so there is only one
  /// client and one token store in the app.
  ApiClient get apiClient => _api;

  Employee? employee;

  /// Set when a Student is signed in. Employee data is not touched.
  AuthUser? studentUser;
  bool get isStudentSignedIn => studentUser != null;

  /// The employee's current case, loaded from the backend.
  ClearanceRequest? activeRequest;

  /// Set when loading cases fails (for example no network).
  String? casesError;

  /// Becomes true when the server says the login token has expired.
  bool sessionExpired = false;

  /// True while a submit request is running. Prevents duplicate submissions.
  bool _submitting = false;
  bool get isSubmitting => _submitting;

  int _caseReadSequence = 0;
  Set<String> _knownCaseIds = {};
  Set<String>? _casesBeforeUncertainSubmit;

  // Form values live here, so they survive moving between screens.
  final ClearanceDraft draft = ClearanceDraft();

  bool get hasActiveRequest => activeRequest != null;

  Future<void> login(String email, String password) async {
    _clearLocalData();
    final user = await _auth.login(email: email, password: password);
    try {
      final profile = await _profile.getProfile();
      employee = Employee.fromProfile(profile, email: user.email);
    } catch (_) {
      // Never stay half logged in.
      await _auth.logout();
      rethrow;
    }
    sessionExpired = false;
    await _loadCasesQuietly();
    notifyListeners();
  }

  /// Student sign-in with the confirmed email/SAP identifier and password. If
  /// the account is not a STUDENT, AuthRepository throws a ROLE_MISMATCH error
  /// and saves nothing.
  Future<void> studentLogin(String identifier, String password) async {
    _clearLocalData();
    final user = await _auth.studentLogin(
      identifier: identifier,
      password: password,
    );
    studentUser = user;
    sessionExpired = false;
    notifyListeners();
  }

  /// Call when the app starts. Returns true if a saved session is still valid.
  Future<bool> restoreSession() async {
    final user = await _auth.restoreSession();
    if (user == null) return false;
    // A saved Student session must not be treated as an Employee session.
    if (user.role == 'STUDENT') {
      studentUser = user;
      sessionExpired = false;
      notifyListeners();
      return true;
    }
    final profile = await _profile.getProfile();
    employee = Employee.fromProfile(profile, email: user.email);
    sessionExpired = false;
    await _loadCasesQuietly();
    notifyListeners();
    return true;
  }

  /// Loads the Employee's saved cases in the backend's newest-first order.
  Future<void> refreshCases() => _loadCases();

  Future<void> _loadCases({bool notify = true}) async {
    final read = ++_caseReadSequence;
    final cases = await _clearance.listCases();
    if (read != _caseReadSequence) return;
    _rememberCases(cases);
    if (notify) notifyListeners();
  }

  void _rememberCases(List<ClearanceRequest> cases) {
    _knownCaseIds = cases.map((item) => item.caseId).toSet();
    final visible = cases.where((item) => item.status != 'CANCELLED');
    activeRequest =
        visible.where((item) => item.status != 'COMPLETED').firstOrNull ??
        visible.firstOrNull;
    casesError = null;
  }

  Future<void> _loadCasesQuietly() async {
    try {
      await _loadCases(notify: false);
    } on ApiException catch (e) {
      casesError = e.message;
    }
  }

  /// Reloads the current case from GET /employee/cases/:caseId.
  /// If no case is known yet, loads the list instead.
  Future<void> refreshActiveCase() async {
    final current = activeRequest;
    if (current == null) {
      await refreshCases();
      return;
    }
    final read = ++_caseReadSequence;
    final saved = await _clearance.getCase(current.caseId);
    if (read != _caseReadSequence) return;
    activeRequest = saved;
    casesError = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _clearLocalData();
    notifyListeners();
  }

  void _handleSessionExpired() {
    _auth.logout();
    _clearLocalData();
    sessionExpired = true;
    notifyListeners();
  }

  void _clearLocalData() {
    employee = null;
    studentUser = null;
    activeRequest = null;
    casesError = null;
    draft.clear();
    _caseReadSequence++;
    _knownCaseIds.clear();
    _casesBeforeUncertainSubmit = null;
  }

  /// Submits the request and keeps the draft if the server does not confirm it.
  Future<void> submit() async {
    if (_submitting) return;

    final owner = employee;
    _submitting = true;
    notifyListeners();
    try {
      final previousIds = _casesBeforeUncertainSubmit;
      if (previousIds != null) {
        final cases = await _clearance.listCases();
        if (!identical(employee, owner)) return;
        _caseReadSequence++;
        _rememberCases(cases);
        _casesBeforeUncertainSubmit = null;

        final saved = cases
            .where(
              (item) =>
                  !previousIds.contains(item.caseId) &&
                  item.status != 'CANCELLED' &&
                  item.lastWorkingDay == draft.lastWorkingDay &&
                  item.reason == draft.reason?.trim() &&
                  item.remarks == draft.remarks.trim(),
            )
            .firstOrNull;
        if (saved != null) {
          activeRequest = saved;
          draft.clear();
          return;
        }
        if (activeRequest != null && activeRequest!.status != 'COMPLETED') {
          throw ApiException(
            message: 'You already have an active clearance case.',
            statusCode: 409,
            code: 'ACTIVE_CASE_EXISTS',
          );
        }
      }

      final caseIdsAtSubmit = Set<String>.of(_knownCaseIds);
      try {
        final saved = await _clearance.submit(draft);
        if (!identical(employee, owner)) return;
        _caseReadSequence++;
        activeRequest = saved;
        _knownCaseIds.add(saved.caseId);
        casesError = null;
        draft.clear();
      } on ApiException catch (e) {
        if (identical(employee, owner) &&
            (e.isNetworkError || e.isServerError)) {
          _casesBeforeUncertainSubmit = caseIdsAtSubmit;
        }
        rethrow;
      }
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
