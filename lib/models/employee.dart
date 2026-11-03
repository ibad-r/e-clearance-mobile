import 'employee_profile.dart';

class Employee {
  final String id;
  final String name;
  final String email;
  final String department;
  final String designation;
  final String joiningDate;
  final String facultyCode;
  final String category;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    required this.joiningDate,
    this.facultyCode = '',
    this.category = '',
  });

  /// Builds the employee from the real backend profile.
  factory Employee.fromProfile(EmployeeProfile p, {required String email}) {
    return Employee(
      id: p.employeeNumber,
      name: p.fullName,
      email: email,
      department: p.departmentName,
      designation: p.designation,
      joiningDate: _formatDate(p.joiningDate),
      facultyCode: p.facultyCode,
      category: p.category,
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year}';
  }
}