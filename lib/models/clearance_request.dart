enum StepStatus { cleared, notApplicable, processing, outstanding, locked }

StepStatus _stageStatus(String? s) {
  switch (s) {
    case 'CLEARED':
      return StepStatus.cleared;
    case 'NOT_APPLICABLE':
    case 'SKIPPED': // Older Employee cases use SKIPPED.
      return StepStatus.notApplicable;
    case 'CHECKING':
    case 'RECHECKING':
      return StepStatus.processing;
    case 'ACTION_REQUIRED':
    case 'OUTSTANDING':
      return StepStatus.outstanding;
    default: // PENDING or legacy LOCKED
      return StepStatus.locked;
  }
}

class DepartmentStep {
  final String? id;
  final String department;
  final StepStatus status;
  final String? note;
  final int stepOrder;
  final bool isRequired;
  final int? amountDue;

  const DepartmentStep({
    this.id,
    required this.department,
    required this.status,
    this.note,
    this.stepOrder = 0,
    this.isRequired = true,
    this.amountDue,
  });

  bool get isEvaluated =>
      status == StepStatus.cleared || status == StepStatus.notApplicable;

  /// Example: PKR 4,500
  String? get amountLabel =>
      amountDue == null ? null : 'PKR ${_withCommas(amountDue!)}';

  factory DepartmentStep.fromJson(Map<String, dynamic> json) {
    return DepartmentStep(
      id: json['id'] as String?,
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

class DepartmentIssue {
  const DepartmentIssue({
    required this.stageId,
    required this.status,
    required this.reason,
  });

  final String stageId;
  final String status;
  final String? reason;

  factory DepartmentIssue.fromJson(Map<String, dynamic> json) =>
      DepartmentIssue(
        stageId: json['requestStageId']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        reason: json['reason'] as String?,
      );
}

/// What the employee types into the request form.
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

  /// Backend case status, e.g. IN_PROGRESS or ACTION_REQUIRED.
  final String status;

  final DateTime? submittedAt;
  final DateTime lastWorkingDay;
  final String reason;
  final String remarks;
  final List<DepartmentStep> steps;
  final List<ApprovalStep> approvals;
  final List<DepartmentIssue> issues;
  final String? certificateId;

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
    this.issues = const [],
    this.certificateId,
    this.totalStages = 0,
    this.clearedStages = 0,
    this.outstandingStages = 0,
    this.skippedStages = 0,
    String phone = '',
    String forwardingAddress = '',
  }) : _caseId = caseId,
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
      submittedAt: DateTime.tryParse(
        json['submittedAt']?.toString() ?? '',
      )?.toLocal(),
      lastWorkingDay: DateTime.parse(json['lastWorkingDate'] as String),
      reason: json['reasonForLeaving']?.toString() ?? '',
      remarks: json['employeeRemarks']?.toString() ?? '',
      steps: stages,
      approvals: approvals,
      issues: (json['issues'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => DepartmentIssue.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      certificateId: json['certificateId'] as String?,
      totalStages: count('totalStages'),
      clearedStages: count('clearedStages'),
      outstandingStages: count('outstandingStages'),
      skippedStages: count('skippedStages'),
    );
  }

  int get clearedCount =>
      steps.where((step) => step.status == StepStatus.cleared).length;

  int get notApplicableCount =>
      steps.where((step) => step.status == StepStatus.notApplicable).length;

  int get evaluatedCount => clearedCount + notApplicableCount;

  int get stageCount => totalStages > steps.length ? totalStages : steps.length;

  double get progress => stageCount == 0 ? 0 : evaluatedCount / stageCount;

  DepartmentStep? get currentStep {
    if (status == 'CANCELLED' || isCompleted) return null;
    for (final step in steps) {
      if (!step.isEvaluated) return step;
    }
    return null;
  }

  DepartmentIssue? openIssueFor(DepartmentStep step) {
    for (final issue in issues) {
      if (issue.stageId == step.id && issue.status == 'OPEN') return issue;
    }
    return null;
  }

  bool get isCompleted =>
      status == 'COMPLETED' &&
      steps.isNotEmpty &&
      steps.length == stageCount &&
      steps.every((step) => !step.isRequired || step.isEvaluated);

  String? get availableCertificateId =>
      isCompleted && (certificateId?.isNotEmpty ?? false)
      ? certificateId
      : null;

  StepStatus get overallStatus {
    if (isCompleted) return StepStatus.cleared;
    if (currentStep?.status == StepStatus.outstanding) {
      return StepStatus.outstanding;
    }
    if (steps.isEmpty) return StepStatus.locked;
    return StepStatus.processing;
  }
}
