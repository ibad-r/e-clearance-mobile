import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../data/student_repository.dart';
import '../models/student_api_models.dart';

enum ClearanceReason { degreeCompleted, discontinuingStudies }

extension ClearanceReasonLabel on ClearanceReason {
  String get label => this == ClearanceReason.degreeCompleted
      ? 'Degree Completed'
      : 'Discontinuing Studies';

  /// Literal sent to the server (confirmed contract values).
  String get apiValue => this == ClearanceReason.degreeCompleted
      ? StudentReasons.degreeCompleted
      : StudentReasons.discontinuingStudies;
}

enum LoadState { loading, ready, error }

enum SubmitOutcome { success, conflict, failed }

enum DepartmentStatus {
  pending,
  inReview,
  cleared,
  actionRequired,
  notRequired,

  /// Applicability not decided yet (for example Laboratory).
  undetermined,
  unknown,
}

/// Only the request-specific reason is editable.
class StudentRequestDraft {
  ClearanceReason? reason;

  void clear() => reason = null;
}

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.sapId,
    required this.registrationNumber,
    required this.fatherName,
    required this.program,
    required this.semester,
    this.email,
  });

  final String name;
  final String sapId;
  final String registrationNumber;
  final String fatherName;
  final String program;
  final String semester;
  final String? email;

  factory StudentProfile.fromDto(StudentProfileDto dto, {String? email}) =>
      StudentProfile(
        name: dto.studentName,
        sapId: dto.sapId,
        registrationNumber: dto.registrationNumber,
        fatherName: dto.fatherName,
        program: dto.program,
        semester: dto.semester,
        email: email,
      );
}

class StudentHistoryItem {
  const StudentHistoryItem({
    required this.referenceNumber,
    required this.type,
    required this.dateLabel,
    required this.statusLabel,
    this.requestId,
  });

  final String referenceNumber;
  final String type;
  final String dateLabel;
  final String statusLabel;

  /// Internal UUID, used for the detail request.
  final String? requestId;
}

/// The real result returned by the server after a request is submitted.
class StudentSubmission {
  const StudentSubmission({
    required this.referenceNumber,
    required this.submittedOn,
    required this.status,
    this.completed = false,
  });

  final String referenceNumber;
  final String submittedOn;
  final String status;

  /// True when the server completed the request automatically at submit.
  final bool completed;
}

/// One department's status as reported by the server.
class DepartmentStatusItem {
  const DepartmentStatusItem({
    required this.name,
    required this.status,
    this.updateText,
    this.code,
    this.reason,
  });

  final String name;
  final DepartmentStatus status;
  final String? updateText;

  /// Backend department code, for example LIBRARY.
  final String? code;

  /// Backend-approved Student-visible reason. Plain text only.
  final String? reason;
}

/// The student's request and department statuses.
class StudentRequestStatus {
  const StudentRequestStatus({
    required this.requestId,
    required this.referenceNumber,
    required this.submittedOn,
    required this.overallStatus,
    required this.departments,
  });

  final String requestId;
  final String referenceNumber;
  final String submittedOn;
  final String overallStatus;
  final List<DepartmentStatusItem> departments;
}

/// Progress counts from GET /student/dashboard.
class StudentProgress {
  const StudentProgress({
    required this.requiredCount,
    required this.clearedRequiredCount,
    required this.actionRequiredCount,
    required this.notRequiredCount,
    required this.undeterminedCount,
  });

  final int requiredCount;
  final int clearedRequiredCount;
  final int actionRequiredCount;
  final int notRequiredCount;
  final int undeterminedCount;

  factory StudentProgress.fromDto(StudentProgressDto d) => StudentProgress(
    requiredCount: d.requiredCount,
    clearedRequiredCount: d.clearedRequiredCount,
    actionRequiredCount: d.actionRequiredCount,
    notRequiredCount: d.notRequiredCount,
    undeterminedCount: d.undeterminedCount,
  );
}

/// Full request record from GET /student/requests/{id}.
class StudentRequestDetail {
  const StudentRequestDetail({
    required this.referenceNumber,
    required this.submittedOn,
    required this.overallStatus,
    required this.reasonLabel,
    required this.departments,
    this.studentName,
    this.sapId,
    this.registrationNumber,
    this.fatherName,
    this.program,
    this.semester,
  });

  final String referenceNumber;
  final String submittedOn;
  final String overallStatus;
  final String reasonLabel;
  final List<DepartmentStatusItem> departments;
  final String? studentName;
  final String? sapId;
  final String? registrationNumber;
  final String? fatherName;
  final String? program;
  final String? semester;
}

// ---------------------------------------------------------------------------
// Mapping helpers (server data -> UI models)
// ---------------------------------------------------------------------------
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _fmtDate(DateTime? d) {
  if (d == null) return 'Not available';
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

String _reasonLabel(String raw) => switch (raw) {
  StudentReasons.degreeCompleted => 'Degree Completed',
  StudentReasons.discontinuingStudies => 'Discontinuing Studies',
  _ => raw,
};

String _parentLabel(StudentRequestSummaryDto s) => switch (s.status) {
  RequestParentStatus.inProgress => 'In progress',
  RequestParentStatus.completed => 'Completed',
  RequestParentStatus.cancelled => 'Cancelled',
  RequestParentStatus.unknown => s.isActive ? 'In progress' : 'Closed',
};

DepartmentStatus _mapStatus(DepartmentApiStatus s) => switch (s) {
  DepartmentApiStatus.pending => DepartmentStatus.pending,
  DepartmentApiStatus.inReview => DepartmentStatus.inReview,
  DepartmentApiStatus.cleared => DepartmentStatus.cleared,
  DepartmentApiStatus.actionRequired => DepartmentStatus.actionRequired,
  DepartmentApiStatus.notRequired => DepartmentStatus.notRequired,
  DepartmentApiStatus.unknown => DepartmentStatus.unknown,
};

/// Undetermined is checked first so it is never shown as cleared or exempt.
DepartmentStatusItem _toDept(DepartmentDto d) => DepartmentStatusItem(
  code: d.code,
  name: d.displayName,
  status: d.isUndetermined
      ? DepartmentStatus.undetermined
      : d.isExempt
      ? DepartmentStatus.notRequired
      : _mapStatus(d.status),
  updateText: d.updatedAt == null ? null : 'Updated ${_fmtDate(d.updatedAt)}',
  reason: d.visibleReason,
);

StudentRequestStatus _toStatus(
    StudentRequestSummaryDto s,
    List<DepartmentDto> deps,
    ) => StudentRequestStatus(
  requestId: s.id,
  referenceNumber: s.requestReference,
  submittedOn: _fmtDate(s.submittedAt),
  overallStatus: _parentLabel(s),
  departments: deps.map(_toDept).toList(),
);

StudentHistoryItem _toHistory(StudentRequestSummaryDto s) => StudentHistoryItem(
  requestId: s.id,
  referenceNumber: s.requestReference,
  type: _reasonLabel(s.reason),
  dateLabel: _fmtDate(s.closedAt ?? s.submittedAt),
  statusLabel: _parentLabel(s),
);

StudentRequestDetail _toDetail(StudentRequestDto d) => StudentRequestDetail(
  referenceNumber: d.summary.requestReference,
  submittedOn: _fmtDate(d.summary.submittedAt),
  overallStatus: _parentLabel(d.summary),
  reasonLabel: _reasonLabel(d.summary.reason),
  departments: d.departments.map(_toDept).toList(),
  studentName: d.studentName,
  sapId: d.sapId,
  registrationNumber: d.registrationNumber,
  fatherName: d.fatherName,
  program: d.program,
  semester: d.semester,
);

/// Safe message for the UI. Never shows raw server details.
String _friendly(ApiException e) {
  if (e.isNetworkError) return e.message;
  if (e.isUnauthorized) return 'Your session has expired. Please log in again.';
  if (e.isForbidden) return 'You do not have access to this information.';
  if (e.isNotFound) return 'The requested record was not found.';
  if (e.isConflict) {
    return 'This action conflicts with an existing request. '
        'Please refresh and try again.';
  }
  if (e.isValidation) {
    return 'Some of the information is not valid. Please check and try again.';
  }
  if (e.statusCode == 503) {
    return 'The clearance service is temporarily unavailable. '
        'Please try again shortly.';
  }
  if (e.isServerError) return 'Server error. Please try again later.';
  return 'Something went wrong. Please try again.';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class StudentState extends ChangeNotifier {
  StudentState({required StudentRepository repository, String? email})
      : _repo = repository,
        _email = email;

  final StudentRepository _repo;
  final String? _email;
  bool _disposed = false;

  /// Set after an uncertain submit (timeout or unreadable reply). The dashboard
  /// must be refreshed before another submit is allowed.
  bool _mustRefreshFirst = false;

  StudentProfile? profile;
  LoadState profileLoad = LoadState.loading;
  String? profileError;
  bool _loadingProfile = false;
  bool get hasVerifiedProfile =>
      profileLoad == LoadState.ready && profile != null;

  LoadState dashboardLoad = LoadState.loading;
  String? dashboardError;
  bool hasActiveRequest = false;
  StudentRequestStatus? currentRequest;
  StudentProgress? progress;
  int closedRequestCount = 0;
  StudentHistoryItem? latestClosed;

  /// Saved results of the latest closed request (for example one that was
  /// completed automatically at submit). Null if it could not be loaded.
  StudentRequestStatus? latestClosedStatus;

  /// The request to show: the active one, or else the latest closed one.
  StudentRequestStatus? get displayRequest =>
      currentRequest ?? latestClosedStatus;

  LoadState historyLoad = LoadState.loading;
  String? historyError;
  List<StudentHistoryItem> history = const [];

  LoadState detailLoad = LoadState.loading;
  String? detailError;
  StudentRequestDetail? detail;

  StudentSubmission? lastSubmission;
  final StudentRequestDraft draft = StudentRequestDraft();
  bool isSubmitting = false;
  String? submitError;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    // A request can finish after the screen is gone (for example after logout).
    if (!_disposed) super.notifyListeners();
  }

  // ---- Profile: GET /student/profile ----
  Future<void> loadProfile() async {
    if (_loadingProfile) return;
    _loadingProfile = true;
    profileLoad = LoadState.loading;
    profile = null;
    profileError = null;
    notifyListeners();
    try {
      final p = await _repo.fetchProfile();
      if (_disposed) return;
      profile = StudentProfile.fromDto(p, email: _email);
      profileLoad = LoadState.ready;
    } on ApiException catch (e) {
      profileLoad = LoadState.error;
      profileError = e.isNotFound
          ? 'Your student profile was not found. Contact the administration.'
          : _friendly(e);
    } catch (_) {
      profileLoad = LoadState.error;
      profileError = 'Could not load your profile. Please try again.';
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  // ---- Dashboard: GET /student/dashboard ----
  /// [quiet] keeps the data already on screen if this refresh fails
  /// (used when the app returns to the foreground and after a submit).
  Future<void> refreshDashboard({bool quiet = false}) async {
    if (dashboardLoad != LoadState.ready) {
      dashboardLoad = LoadState.loading;
      dashboardError = null;
      notifyListeners();
    }
    try {
      final dto = await _repo.fetchDashboard();
      // Only /student/profile updates verified form data. Dashboard loads are independent.
      final active = dto.activeRequest;
      hasActiveRequest = active != null;
      currentRequest = active == null
          ? null
          : _toStatus(active, dto.departments);
      final p = dto.progress;
      progress = p == null ? null : StudentProgress.fromDto(p);
      closedRequestCount = dto.closedRequestCount;
      final closed = dto.latestClosedRequest;
      latestClosed = closed == null ? null : _toHistory(closed);

      // A completed request is no longer "active", so the dashboard returns no
      // departments for it. Load its saved results by UUID.
      if (active == null && closed != null) {
        latestClosedStatus = await _loadClosedStatus(closed);
      } else {
        latestClosedStatus = null;
      }

      dashboardLoad = LoadState.ready;
      dashboardError = null;
    } on ApiException catch (e) {
      // A failed load is an error, never "no active request".
      if (!(quiet && dashboardLoad == LoadState.ready)) {
        dashboardLoad = LoadState.error;
        dashboardError = _friendly(e);
      }
    } catch (_) {
      if (!(quiet && dashboardLoad == LoadState.ready)) {
        dashboardLoad = LoadState.error;
        dashboardError = 'Unexpected error. Please try again.';
      }
    }
    notifyListeners();
  }

  Future<StudentRequestStatus?> _loadClosedStatus(
      StudentRequestSummaryDto closed,
      ) async {
    try {
      final full = await _repo.fetchRequest(closed.id);
      return _toStatus(full.summary, full.departments);
    } catch (_) {
      // The history card is still shown; department results are just missing.
      return null;
    }
  }

  // ---- History: GET /student/requests ----
  Future<void> loadHistory() async {
    historyLoad = LoadState.loading;
    historyError = null;
    notifyListeners();
    try {
      final list = await _repo.listRequests();
      history = list.where((r) => !r.isActive).map(_toHistory).toList();
      historyLoad = LoadState.ready;
    } on ApiException catch (e) {
      historyLoad = LoadState.error;
      historyError = _friendly(e);
    } catch (_) {
      historyLoad = LoadState.error;
      historyError = 'Unexpected error. Please try again.';
    }
    notifyListeners();
  }

  // ---- Request details: GET /student/requests/{id} ----
  Future<void> loadDetail() async {
    // displayRequest also covers a request that completed at submit, before
    // the dashboard has been reloaded.
    final id = displayRequest?.requestId ?? latestClosed?.requestId;
    if (id == null) {
      detail = null;
      detailLoad = LoadState.ready;
      notifyListeners();
      return;
    }
    detailLoad = LoadState.loading;
    detailError = null;
    notifyListeners();
    try {
      detail = _toDetail(await _repo.fetchRequest(id));
      detailLoad = LoadState.ready;
    } on ApiException catch (e) {
      detailLoad = LoadState.error;
      detailError = e.isNotFound
          ? 'This request could not be found.'
          : _friendly(e);
    } catch (_) {
      detailLoad = LoadState.error;
      detailError = 'Unexpected error. Please try again.';
    }
    notifyListeners();
  }

  // ---- Submit: POST /student/requests ----
  Future<SubmitOutcome> submitRequest({StudentProfile? reviewedProfile}) async {
    if (isSubmitting) return SubmitOutcome.failed; // no duplicate taps
    final p = profile;
    if (!hasVerifiedProfile || p == null) {
      submitError = 'Load your verified student profile before submitting.';
      notifyListeners();
      return SubmitOutcome.failed;
    }
    if (reviewedProfile != null && !identical(reviewedProfile, p)) {
      submitError =
      'Your student details have changed. Return to the request form and review again.';
      notifyListeners();
      return SubmitOutcome.failed;
    }
    final reason = draft.reason;
    if (reason == null) {
      submitError = 'Please select a clearance reason.';
      notifyListeners();
      return SubmitOutcome.failed;
    }

    isSubmitting = true;
    submitError = null;
    notifyListeners();
    try {
      if (_mustRefreshFirst) {
        // The last submit may or may not have reached the server.
        await refreshDashboard();
        if (dashboardLoad == LoadState.error) {
          submitError =
          'We could not confirm your earlier submission. '
              'Please check your connection and try again.';
          return SubmitOutcome.failed;
        }
        _mustRefreshFirst = false;
        if (hasActiveRequest) {
          submitError = 'You already have an active clearance request.';
          return SubmitOutcome.conflict;
        }
      }

      final created = await _repo.createRequest(
        registrationNumber: p.registrationNumber,
        fatherName: p.fatherName,
        program: p.program,
        semester: p.semester,
        reason: reason.apiValue,
      );

      // Success only after the server answered 201 with a valid request.
      final s = created.summary;
      final status = _toStatus(s, created.departments);
      lastSubmission = StudentSubmission(
        referenceNumber: s.requestReference,
        submittedOn: _fmtDate(s.submittedAt),
        status: status.overallStatus,
        completed: s.status == RequestParentStatus.completed,
      );
      hasActiveRequest = s.isActive;
      currentRequest = s.isActive ? status : null;
      // Immediate completion: keep the returned results and ID, because the
      // request is no longer the dashboard's active request.
      latestClosedStatus = s.isActive ? null : status;
      // Progress comes from the dashboard. The confirmation screen reloads it.
      progress = null;
      dashboardLoad = LoadState.ready;
      dashboardError = null;
      return SubmitOutcome.success;
    } on ApiException catch (e) {
      if (e.code == 'PROFILE_MISMATCH') {
        profile = null;
        profileLoad = LoadState.error;
        profileError =
        'Your student details have changed. Reload your profile and review the request again.';
        submitError = profileError;
        return SubmitOutcome.failed;
      }
      if (e.isActiveRequestExists) {
        await refreshDashboard();
        submitError = 'You already have an active clearance request.';
        return SubmitOutcome.conflict;
      }
      if (e.isNetworkError) {
        // Timeout or unreadable reply: the request may have been created.
        _mustRefreshFirst = true;
        submitError =
        '${e.message} Your request may not have been sent. '
            'We will check before you try again.';
        return SubmitOutcome.failed;
      }
      submitError = _friendly(e);
      return SubmitOutcome.failed;
    } catch (_) {
      _mustRefreshFirst = true;
      submitError = 'Unexpected error. We will check before you try again.';
      return SubmitOutcome.failed;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}