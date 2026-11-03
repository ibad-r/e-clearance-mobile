class EmployeeProfile {
  const EmployeeProfile({
    required this.employeeNumber,
    required this.fullName,
    required this.designation,
    required this.facultyCode,
    required this.departmentName,
    required this.joiningDate,
    required this.category,
  });

  final String employeeNumber;
  final String fullName;
  final String designation;
  final String facultyCode;
  final String departmentName;
  final DateTime? joiningDate;
  final String category;

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      employeeNumber: json['employeeNumber']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      facultyCode: json['facultyCode']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      joiningDate: DateTime.tryParse(json['joiningDate']?.toString() ?? ''),
      category: json['category']?.toString() ?? '',
    );
  }

  /// Two letters for the avatar, taken from the real name.
  String get initials {
    final parts =
    fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final list = parts.toList();
    final first = list.first[0];
    final last = list.length > 1 ? list.last[0] : '';
    return (first + last).toUpperCase();
  }
}