enum StepStatus { cleared, processing, outstanding, locked }

StepStatus _stageStatus(String? s) {
  switch (s) {
    case 'CLEARED':
    case 'SKIPPED': // a skipped stage does not block clearance
      return StepStatus.cleared;
    case 'CHECKING':
    case 'RECHECKING':
      return StepStatus.processing;
    case 'OUTSTANDING':
      return StepStatus.outstanding;
    default: // LOCKED
      return StepStatus.locked;
  }
}

class DepartmentStep {
  final String department;
  final StepStatus status;
  final String? note;
  final int stepOrder;
  final bool isRequired;
  final int? amountDue;

  const DepartmentStep({
    required this.department,
    required this.status,
    this.note,
    this.stepOrder = 0,
    this.isRequired = true,
    this.amountDue,
  });

  /// Example: PKR 4,500
  String? get amountLabel =>
      amountDue == null ? null : 'PKR ${_withCommas(amountDue!)}';

  factory DepartmentStep.fromJson(Map<String, dynamic> json) {
    return DepartmentStep(
      department: json['departmentName']?.toString() ?? 'Department',
      status: _stageStatus(json['status']?.toString()),
      note: json['outstandingNote']?.toString(),
      stepOrder: (json['stepOrder'] as num?)?.toInt() ?? 0,
      isRequired: json['isRequired'] as bool? ?? true,
    );
  }
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

class ApprovalStep {
  final String positionTitle;
  final String status; // WAITING, PENDING, APPROVED, RETURNED, SKIPPED
  final int stepOrder;

  const ApprovalStep({
    required this.positionTitle,
    required this.status,
    required this.stepOrder,
  });

  factory ApprovalStep.fromJson(Map<String, dynamic> json) {
    return ApprovalStep(
      positionTitle: json['positionTitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      stepOrder: (json['stepOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// What the employee types into the form. Only these three values
/// are sent to the server.
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

/// A real clearance case returned by the backend.
class ClearanceRequest {
  final String _caseId;

  /// Database ID of the case (used for GET /employee/cases/:caseId).
  String get caseId => _caseId.isEmpty ? id : _caseId;

  /// The request code shown to the user (from the backend `requestCode`).
  final String id;

  /// Backend case status, e.g. IN_PROGRESS.
  final String status;

  final DateTime? submittedAt;
  final DateTime lastWorkingDay;
  final String reason;
  final String remarks;
  final List<DepartmentStep> steps;
  final List<ApprovalStep> approvals;

  /// Progress counts exactly as sent by the backend.
  final int totalStages;
  final int clearedStages;
  final int outstandingStages;
  final int skippedStages;

  final String _phone;
  final String _forwardingAddress;

  String get phone => _phone;
  String get forwardingAddress => _forwardingAddress;

  const ClearanceRequest({
    String caseId = '',
    required this.id,
    this.status = 'IN_PROGRESS',
    required this.submittedAt,
    required this.lastWorkingDay,
    required this.reason,
    required this.remarks,
    required this.steps,
    this.approvals = const [],
    this.totalStages = 0,
    this.clearedStages = 0,
    this.outstandingStages = 0,
    this.skippedStages = 0,
    String phone = '',
    String forwardingAddress = '',
  })  : _caseId = caseId,
        _phone = phone,
        _forwardingAddress = forwardingAddress;

  factory ClearanceRequest.fromJson(Map<String, dynamic> json) {
    final stages = (json['stages'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => DepartmentStep.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    stages.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    final approvals = (json['approvals'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ApprovalStep.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    approvals.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    final progress = json['progress'] is Map
        ? Map<String, dynamic>.from(json['progress'] as Map)
        : const <String, dynamic>{};
    int count(String key) => (progress[key] as num?)?.toInt() ?? 0;

    return ClearanceRequest(
      caseId: json['id'] as String,
      id: json['requestCode'] as String,
      status: json['status']?.toString() ?? '',
      submittedAt:
      DateTime.tryParse(json['submittedAt']?.toString() ?? '')?.toLocal(),
      lastWorkingDay: DateTime.parse(json['lastWorkingDate'] as String),
      reason: json['reasonForLeaving']?.toString() ?? '',
      remarks: json['employeeRemarks']?.toString() ?? '',
      steps: stages,
      approvals: approvals,
      totalStages: count('totalStages'),
      clearedStages: count('clearedStages'),
      outstandingStages: count('outstandingStages'),
      skippedStages: count('skippedStages'),
    );
  }

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