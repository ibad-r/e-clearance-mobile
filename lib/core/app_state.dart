import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../models/clearance_request.dart';
import '../data/repositories.dart';

class AppState extends ChangeNotifier {
  AppState({AuthRepository? auth, ClearanceRepository? clearance})
      : _auth = auth ?? MockAuthRepository(),
        _clearance = clearance ?? MockClearanceRepository();

  final AuthRepository _auth;
  final ClearanceRepository _clearance;

  Employee? employee;
  ClearanceRequest? activeRequest;

  // Form values live here, so they survive moving between screens.
  // Starting values match the Figma prototype.
  final ClearanceDraft draft = ClearanceDraft()
    ..lastWorkingDay = DateTime(2026, 10, 15)
    ..reason = 'Contract Completion'
    ..phone = '+92 300 0000142';

  bool get hasActiveRequest => activeRequest != null;

  Future<void> login(String email, String password) async {
    employee = await _auth.login(email, password);
    notifyListeners();
  }

  Future<void> submit() async {
    activeRequest = await _clearance.submit(draft);
    draft.clear();
    notifyListeners();
  }
}