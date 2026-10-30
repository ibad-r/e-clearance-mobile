import '../models/employee.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

abstract class AuthRepository {
  Future<Employee> login(String email, String password);
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
    );
  }
}