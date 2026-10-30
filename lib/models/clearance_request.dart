enum StepStatus { cleared, processing, outstanding, locked }

class DepartmentStep {
  final String department;
  final StepStatus status;
  final String? note;

  const DepartmentStep({
    required this.department,
    required this.status,
    this.note,
  });
}

class ClearanceDraft {
  DateTime? lastWorkingDay;
  String? reason;
  String phone = '';
  String email = '';
  String remarks = '';
  bool confirmed = false;
}

class ClearanceRequest {
  final String id;
  final DateTime submittedAt;
  final DateTime lastWorkingDay;
  final String reason;
  final String phone;
  final String email;
  final String remarks;
  final List<DepartmentStep> steps;

  const ClearanceRequest({
    required this.id,
    required this.submittedAt,
    required this.lastWorkingDay,
    required this.reason,
    required this.phone,
    required this.email,
    required this.remarks,
    required this.steps,
  });

  int get clearedCount =>
      steps.where((s) => s.status == StepStatus.cleared).length;

  double get progress => steps.isEmpty ? 0 : clearedCount / steps.length;
}