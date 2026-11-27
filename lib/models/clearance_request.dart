import 'department_questionnaire.dart';

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

/// HR confirmation metadata. Null on the case until HR has confirmed.
class HrSelection {
  const HrSelection({this.verifiedAt, this.selectionRevision = 0});

  final DateTime? verifiedAt;
  final int selectionRevision;

  factory HrSelection.fromJson(Map<String, dynamic> json) => HrSelection(
    verifiedAt: DateTime.tryParse(json['verifiedAt']?.toString() ?? '')
        ?.toLocal(),
    selectionRevision: (json['selectionRevision'] as num?)?.toInt() ?? 0,
  );
}

/// A department the backend suggests. Advice only, never a requirement.
class RecommendedDepartment {
  const RecommendedDepartment({
    required this.departmentId,
    required this.departmentCode,
    required this.departmentName,
    this.reason,
  });

  final String departmentId;
  final String departmentCode;
  final String departmentName;
  final String? reason;

  factory RecommendedDepartment.fromJson(Map<String, dynamic> json) =>
      RecommendedDepartment(
        departmentId: json['departmentId']?.toString() ?? '',
        departmentCode: json['departmentCode']?.toString() ?? '',
        departmentName: json['departmentName']?.toString() ?? '',
        reason: json['reason']?.toString(),
      );
}

/// Parsed so nothing breaks, but NOT shown on the Employee screens.
/// Recommendations must never be displayed as confirmed requirements.
class DepartmentRecommendation {
  const DepartmentRecommendation({
    required this.status,
    this.ruleVersion,
    this.departments = const [],
  });

  /// AVAILABLE or UNAVAILABLE.
  final String status;
  final String? ruleVersion;
  final List<RecommendedDepartment> departments;

  factory DepartmentRecommendation.fromJson(Map<String, dynamic> json) {
    final list = (json['departments'] as List? ?? const [])
        .whereType<Map>()
        .map((m) =>
        RecommendedDepartment.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return DepartmentRecommendation(
      status: json['status']?.toString() ?? 'UNAVAILABLE',
      ruleVersion: json['ruleVersion']?.toString(),
      departments: list,
    );
  }
}

/// What the employee types into the form. The form values and the
/// questionnaire answers are sent to the server. Nothing else.
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
  static const pendingHrStatus = 'PENDING_HR_VERIFICATION';

  final String _caseId;

  /// Database ID of the case (used for GET /employee/cases/:caseId).
  String get caseId => _caseId.isEmpty ? id : _caseId;

  /// The request code shown to the user (from the backend `requestCode`).
  final String id;

  /// Backend case status, e.g. IN_PROGRESS or PENDING_HR_VERIFICATION.
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

  /// Null on old cases submitted before the questionnaire existed.
  final String? questionnaireVersion;
  final Map<String, QuestionAnswer>? questionnaireAnswers;

  /// Parsed only. Never displayed on the Employee screens.
  final DepartmentRecommendation? recommendation;

  /// Null until HR confirms the applicable departments.
  final HrSelection? hrSelection;
  final List<String> confirmedDepartmentIds;

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
    this.questionnaireVersion,
    this.questionnaireAnswers,
    this.recommendation,
    this.hrSelection,
    this.confirmedDepartmentIds = const [],
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

    // Questionnaire answers: only exact YES / NO / NOT_SURE are accepted.
    Map<String, QuestionAnswer>? answers;
    final rawAnswers = json['questionnaireAnswers'];
    if (rawAnswers is Map) {
      answers = {};
      rawAnswers.forEach((k, v) {
        final a = questionAnswerFromApi(v?.toString());
        if (a != null) answers![k.toString()] = a;
      });
    }

    final rawRecommendation = json['departmentRecommendation'];
    final rawSelection = json['hrSelection'];

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
      questionnaireVersion: json['questionnaireVersion']?.toString(),
      questionnaireAnswers: answers,
      recommendation: rawRecommendation is Map
          ? DepartmentRecommendation.fromJson(
          Map<String, dynamic>.from(rawRecommendation))
          : null,
      hrSelection: rawSelection is Map
          ? HrSelection.fromJson(Map<String, dynamic>.from(rawSelection))
          : null,
      confirmedDepartmentIds:
      (json['confirmedDepartmentIds'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// True while HR has not yet confirmed which departments apply.
  /// Stages are empty in this state. That is NOT a completed clearance.
  bool get isPendingHr => status == pendingHrStatus;

  /// True only after HR confirmed (or on old cases that already have stages).
  bool get hasConfirmedStages => steps.isNotEmpty;

  int get clearedCount =>
      steps.where((s) => s.status == StepStatus.cleared).length;

  /// 0 when there are no stages. Zero never means complete.
  double get progress => steps.isEmpty ? 0 : clearedCount / steps.length;

  /// First stage that is not cleared yet (null when everything is cleared).
  DepartmentStep? get currentStep {
    for (final step in steps) {
      if (step.status != StepStatus.cleared) return step;
    }
    return null;
  }

  /// Overall status shown on the dashboard and progress screens.
  /// With no stages (for example Pending HR) nothing has started, so the
  /// status is locked, never processing and never cleared.
  StepStatus get overallStatus {
    if (steps.isEmpty) return StepStatus.locked;
    if (clearedCount == steps.length) return StepStatus.cleared;
    if (steps.any((s) => s.status == StepStatus.outstanding)) {
      return StepStatus.outstanding;
    }
    return StepStatus.processing;
  }
}