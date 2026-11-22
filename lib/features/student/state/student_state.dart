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
  });

  final String referenceNumber;
  final String type;
  final String dateLabel;
  final String statusLabel;
}

/// The real result returned by the server after a request is submitted.
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

/// The student's current request and department statuses.
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

DepartmentStatus _mapStatus(DepartmentApiStatus s) => switch (s) {
  DepartmentApiStatus.pending => DepartmentStatus.pending,
  DepartmentApiStatus.inReview => DepartmentStatus.inReview,
  DepartmentApiStatus.cleared => DepartmentStatus.cleared,
  DepartmentApiStatus.actionRequired => DepartmentStatus.actionRequired,
  DepartmentApiStatus.notRequired => DepartmentStatus.notRequired,
  DepartmentApiStatus.unknown => DepartmentStatus.unknown,
};

/// Remarks are not shown until Student visibility is confirmed.
DepartmentStatusItem _toDept(DepartmentDto d) => DepartmentStatusItem(
  name: d.displayName,
  status: _mapStatus(d.status),
  updateText: d.updatedAt == null ? null : 'Updated ${_fmtDate(d.updatedAt)}',
);

StudentRequestStatus _toStatus(
  StudentRequestSummaryDto s,
  List<DepartmentDto> deps,
) => StudentRequestStatus(
  requestId: s.id,
  referenceNumber: s.requestReference,
  submittedOn: _fmtDate(s.submittedAt),
  overallStatus: s.isActive ? 'Active' : 'Closed',
  departments: deps.map(_toDept).toList(),
);

StudentHistoryItem _toHistory(StudentRequestSummaryDto s) => StudentHistoryItem(
  referenceNumber: s.requestReference,
  type: _reasonLabel(s.reason),
  dateLabel: _fmtDate(s.closedAt ?? s.submittedAt),
  statusLabel: s.isActive ? 'Active' : 'Closed',
);

StudentRequestDetail _toDetail(StudentRequestDto d) => StudentRequestDetail(
  referenceNumber: d.summary.requestReference,
  submittedOn: _fmtDate(d.summary.submittedAt),
  overallStatus: d.summary.isActive ? 'Active' : 'Closed',
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
  if (e.isValidation) {
    return 'Some of the information is not valid. Please check and try again.';
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
  int closedRequestCount = 0;
  StudentHistoryItem? latestClosed;

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
  Future<void> refreshDashboard() async {
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
      closedRequestCount = dto.closedRequestCount;
      final closed = dto.latestClosedRequest;
      latestClosed = closed == null ? null : _toHistory(closed);
      dashboardLoad = LoadState.ready;
      dashboardError = null;
    } on ApiException catch (e) {
      // A failed load is an error, never "no active request".
      dashboardLoad = LoadState.error;
      dashboardError = _friendly(e);
    } catch (_) {
      dashboardLoad = LoadState.error;
      dashboardError = 'Unexpected error. Please try again.';
    }
    notifyListeners();
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
    final id = currentRequest?.requestId;
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
      lastSubmission = StudentSubmission(
        referenceNumber: s.requestReference,
        submittedOn: _fmtDate(s.submittedAt),
        status: s.isActive ? 'Active' : 'Closed',
      );
      hasActiveRequest = s.isActive;
      currentRequest = s.isActive ? _toStatus(s, created.departments) : null;
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
