import 'package:flutter/foundation.dart';

enum ClearanceReason { degreeCompleted, discontinuingStudies }

extension ClearanceReasonLabel on ClearanceReason {
  String get label => this == ClearanceReason.degreeCompleted
      ? 'Degree Completed'
      : 'Discontinuing Studies';
}

/// Values the student types in the request form. Kept here so they survive
/// navigation between the form and the review screen.
class StudentRequestDraft {
  String registrationNumber = '';
  String fatherName = '';
  String program = '';
  String semester = '';
  ClearanceReason? reason;
}

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.sapId,
    required this.program,
  });

  final String name;
  final String sapId;
  final String program;
}

class StudentHistoryItem {
  const StudentHistoryItem({
    required this.referenceNumber,
    required this.type,
    required this.dateLabel,
    required this.statusLabel,
  });

  final String referenceNumber;
  final String type;
  final String dateLabel;
  final String statusLabel;
}

/// The real result returned by the server after a request is submitted.
/// Stays null until the Student API is integrated.
class StudentSubmission {
  const StudentSubmission({
    required this.referenceNumber,
    required this.submittedOn,
    required this.status,
  });

  final String referenceNumber;
  final String submittedOn;
  final String status;
}

enum DepartmentStatus { pending, cleared, notRequired }

/// One department's status as reported by the server.
class DepartmentStatusItem {
  const DepartmentStatusItem({
    required this.name,
    required this.status,
    this.updateText,
  });

  final String name;
  final DepartmentStatus status;
  final String? updateText;
}

/// The student's current request and department statuses, as reported by the
/// server. Stays null until the Student API is integrated.
class StudentRequestStatus {
  const StudentRequestStatus({
    required this.referenceNumber,
    required this.submittedOn,
    required this.overallStatus,
    required this.departments,
  });

  final String referenceNumber;
  final String submittedOn;
  final String overallStatus;
  final List<DepartmentStatusItem> departments;
}

/// Holds Student data. Everything starts empty and is filled by the Student
/// API later (not available yet, so no fake data is created here).
class StudentState extends ChangeNotifier {
  StudentProfile? profile;
  bool hasActiveRequest = false;
  List<StudentHistoryItem> history = const [];
  StudentSubmission? lastSubmission;
  StudentRequestStatus? currentRequest;
  final StudentRequestDraft draft = StudentRequestDraft();
}