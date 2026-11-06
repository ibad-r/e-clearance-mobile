import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../models/clearance_request.dart';
import '../data/clearance_repository.dart';
import '../data/profile_repository.dart';
import 'auth/auth_repository.dart';
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

  Employee? employee;

  /// The employee's current case, loaded from the backend.
  ClearanceRequest? activeRequest;

  /// Set when loading cases fails (for example no network).
  String? casesError;

  /// Becomes true when the server says the login token has expired.
  bool sessionExpired = false;

  /// True while a submit request is running. Prevents duplicate submissions.
  bool _submitting = false;
  bool get isSubmitting => _submitting;

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

  /// Call when the app starts. Returns true if a saved session is still valid.
  Future<bool> restoreSession() async {
    final user = await _auth.restoreSession();
    if (user == null) return false;
    final profile = await _profile.getProfile();
    employee = Employee.fromProfile(profile, email: user.email);
    sessionExpired = false;
    await _loadCasesQuietly();
    notifyListeners();
    return true;
  }

  /// Loads the employee's cases from the backend.
  /// Call this when the Progress or Dashboard screen opens.
  Future<void> refreshCases() async {
    final cases = await _clearance.listCases();
    final open = cases.where((c) => c.status != 'CANCELLED').toList();
    open.sort((a, b) => _time(b).compareTo(_time(a)));
    activeRequest = open.isEmpty ? null : open.first;
    casesError = null;
    notifyListeners();
  }

  DateTime _time(ClearanceRequest c) =>
      c.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _loadCasesQuietly() async {
    try {
      final cases = await _clearance.listCases();
      final open = cases.where((c) => c.status != 'CANCELLED').toList();
      open.sort((a, b) => _time(b).compareTo(_time(a)));
      activeRequest = open.isEmpty ? null : open.first;
      casesError = null;
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
    activeRequest = await _clearance.getCase(current.caseId);
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
    activeRequest = null;
    casesError = null;
    draft.clear();
  }

  /// Sends the request to the backend. The case only exists after the
  /// server confirms it. Any error is thrown to the screen.
  Future<void> submit() async {
    if (_submitting) return;
    _submitting = true;
    notifyListeners();
    try {
      activeRequest = await _clearance.submit(draft);
      draft.clear();
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}