import 'package:flutter/foundation.dart';

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

/// Holds Student data. Everything starts empty and is filled by the Student
/// API later (not available yet, so no fake data is created here).
class StudentState extends ChangeNotifier {
  StudentProfile? profile;
  bool hasActiveRequest = false;
  List<StudentHistoryItem> history = const [];
}