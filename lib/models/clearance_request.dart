enum StepStatus { cleared, processing, outstanding, locked }

class DepartmentStep {
  final String department;
  final StepStatus status;
  final String? note;
  final int? amountDue;

  const DepartmentStep({
    required this.department,
    required this.status,
    this.note,
    this.amountDue,
  });

  /// Example: PKR 4,500
  String? get amountLabel =>
      amountDue == null ? null : 'PKR ${_withCommas(amountDue!)}';
}

String _withCommas(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class ClearanceDraft {
  DateTime? lastWorkingDay;
  String? reason;
  String phone = '';
  String forwardingAddress = '';
  String remarks = '';
  bool confirmed = false;

  void clear() {
    lastWorkingDay = null;
    reason = null;
    phone = '';
    forwardingAddress = '';
    remarks = '';
    confirmed = false;
  }
}

class ClearanceRequest {
  final String id;
  final DateTime submittedAt;
  final DateTime lastWorkingDay;
  final String reason;
  final String phone;
  final String forwardingAddress;
  final String remarks;
  final List<DepartmentStep> steps;

  const ClearanceRequest({
    required this.id,
    required this.submittedAt,
    required this.lastWorkingDay,
    required this.reason,
    required this.phone,
    required this.forwardingAddress,
    required this.remarks,
    required this.steps,
  });

  int get clearedCount =>
      steps.where((s) => s.status == StepStatus.cleared).length;

  double get progress => steps.isEmpty ? 0 : clearedCount / steps.length;

  /// First stage that is not cleared yet (null when everything is cleared).
  DepartmentStep? get currentStep {
    for (final step in steps) {
      if (step.status != StepStatus.cleared) return step;
    }
    return null;
  }

  /// Overall status shown on the dashboard and progress screens.
  StepStatus get overallStatus {
    if (steps.isNotEmpty && clearedCount == steps.length) {
      return StepStatus.cleared;
    }
    if (steps.any((s) => s.status == StepStatus.outstanding)) {
      return StepStatus.outstanding;
    }
    return StepStatus.processing;
  }
}