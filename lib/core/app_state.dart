import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../models/clearance_request.dart';
import '../data/repositories.dart' hide AuthRepository, MockAuthRepository;
import '../data/profile_repository.dart';
import 'auth/auth_repository.dart' as real;
import 'network/api_client.dart';

class AppState extends ChangeNotifier {
  AppState({
    ApiClient? apiClient,
    real.AuthRepository? auth,
    ProfileRepository? profile,
    ClearanceRepository? clearance,
  })  : _api = apiClient ?? ApiClient(),
        _clearance = clearance ?? MockClearanceRepository() {
    _auth = auth ?? real.AuthRepository(apiClient: _api);
    _profile = profile ?? ProfileRepository(apiClient: _api);
    _api.onUnauthorized = _handleSessionExpired;
  }

  final ApiClient _api;
  late final real.AuthRepository _auth;
  late final ProfileRepository _profile;
  final ClearanceRepository _clearance; // Step 6 replaces this with the real one

  Employee? employee;
  ClearanceRequest? activeRequest;

  /// Becomes true when the server says the login token has expired.
  bool sessionExpired = false;

  // Form values live here, so they survive moving between screens.
  // (Step 6 cleans these starting values.)
  final ClearanceDraft draft = ClearanceDraft()
    ..lastWorkingDay = DateTime(2026, 10, 15)
    ..reason = 'Contract Completion'
    ..phone = '+92 300 0000142';

  bool get hasActiveRequest => activeRequest != null;

  Future<void> login(String email, String password) async {
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
    draft.clear();
  }

  Future<void> submit() async {
    activeRequest = await _clearance.submit(draft);
    draft.clear();
    notifyListeners();
  }
}