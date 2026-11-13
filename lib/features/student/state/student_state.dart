import 'package:flutter/foundation.dart';

enum ClearanceReason { degreeCompleted, discontinuingStudies }

extension ClearanceReasonLabel on ClearanceReason {
  String get label => this == ClearanceReason.degreeCompleted
      ? 'Degree Completed'
      : 'Discontinuing Studies';
}

enum AppearanceChoice { light, dark, system }

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
    this.registrationNumber,
    this.email,
  });

  final String name;
  final String sapId;
  final String program;
  final String? registrationNumber;
  final String? email;
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

enum DashboardLoadState { ready, loading, error }

/// Holds Student data. Everything starts empty and is filled by the Student
/// API later (not available yet, so no fake data is created here).
class StudentState extends ChangeNotifier {
  StudentProfile? profile;
  bool hasActiveRequest = false;
  List<StudentHistoryItem> history = const [];
  StudentSubmission? lastSubmission;
  StudentRequestStatus? currentRequest;
  final StudentRequestDraft draft = StudentRequestDraft();

  AppearanceChoice _appearance = AppearanceChoice.light;
  AppearanceChoice get appearance => _appearance;

  void setAppearance(AppearanceChoice value) {
    _appearance = value;
    notifyListeners();
  }

  // ---- Dashboard load state (loading / ready / error) ----
  DashboardLoadState dashboardLoad = DashboardLoadState.ready;
  String? dashboardError;

  /// True only while the local DEMO/PREVIEW sample is shown (Phase 1).
  bool isPreview = false;

  /// Phase 1: there is no server yet, so this only resets the local load flags.
  /// Phase 2: load GET /student/dashboard here and set ready or error.
  Future<void> refreshDashboard() async {
    dashboardLoad = DashboardLoadState.loading;
    dashboardError = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    dashboardLoad = DashboardLoadState.ready;
    notifyListeners();
  }

  // ---- Local DEMO/PREVIEW helpers for Phase 1 screenshots (debug only) ----
  void previewActive() {
    isPreview = true;
    hasActiveRequest = true;
    dashboardLoad = DashboardLoadState.ready;
    dashboardError = null;
    currentRequest = const StudentRequestStatus(
      referenceNumber: 'DEMO-0001',
      submittedOn: 'Demo date',
      overallStatus: 'In progress',
      departments: [
        DepartmentStatusItem(name: 'Library', status: DepartmentStatus.cleared),
        DepartmentStatusItem(
            name: 'Fee & Dues Department', status: DepartmentStatus.pending),
        DepartmentStatusItem(
            name: 'Student Service Department',
            status: DepartmentStatus.pending),
        DepartmentStatusItem(
            name: 'Laboratory (if required)', status: DepartmentStatus.pending),
        DepartmentStatusItem(
            name: 'Coordination Office', status: DepartmentStatus.pending),
      ],
    );
    notifyListeners();
  }

  void previewEmpty() {
    isPreview = false;
    hasActiveRequest = false;
    currentRequest = null;
    dashboardLoad = DashboardLoadState.ready;
    dashboardError = null;
    notifyListeners();
  }

  void previewError() {
    dashboardLoad = DashboardLoadState.error;
    dashboardError =
    'Could not load your dashboard. Check your connection and try again.';
    notifyListeners();
  }

  void previewLoading() {
    dashboardLoad = DashboardLoadState.loading;
    notifyListeners();
  }
}