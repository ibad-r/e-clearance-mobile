import '../models/employee.dart';
import '../models/clearance_request.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

abstract class AuthRepository {
  Future<Employee> login(String email, String password);
}

abstract class ClearanceRepository {
  Future<ClearanceRequest> submit(ClearanceDraft draft);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<Employee> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password != 'Password@123') {
      throw const AuthException('Invalid email or password.');
    }
    return Employee(
      id: 'EMP-2026-0142',
      name: 'Ahsan Khan',
      email: email,
      department: 'Faculty of Computing',
      designation: 'Lecturer',
      joiningDate: '01 September 2022',
    );
  }
}

class MockClearanceRepository implements ClearanceRepository {
  @override
  Future<ClearanceRequest> submit(ClearanceDraft draft) async {
    await Future.delayed(const Duration(seconds: 1));
    return ClearanceRequest(
      id: 'CLR-2026-0001',
      submittedAt: DateTime.now(),
      lastWorkingDay: draft.lastWorkingDay!,
      reason: draft.reason!,
      phone: draft.phone,
      forwardingAddress: draft.forwardingAddress,
      remarks: draft.remarks,
      // Mock data only. The backend will replace this later.
      steps: const [
        DepartmentStep(
          department: 'Finance',
          status: StepStatus.outstanding,
          note: 'Outstanding balance',
          amountDue: 4500,
        ),
        DepartmentStep(
            department: 'Information Services / Library',
            status: StepStatus.locked),
        DepartmentStep(
            department: 'Computer Services', status: StepStatus.locked),
        DepartmentStep(department: 'Store', status: StepStatus.locked),
        DepartmentStep(
            department: 'HOD Clearance', status: StepStatus.locked),
      ],
    );
  }
}
