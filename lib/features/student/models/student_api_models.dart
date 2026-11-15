import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';

/// Proposed reason literals from the Student contract (confirm with Ibad).
class StudentReasons {
  static const degreeCompleted = 'degree completed';
  static const discontinuingStudies = 'discontinuing studies';
}

ApiException _unexpected() =>
    ApiException(message: 'Unexpected response from the server.');

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  throw _unexpected();
}

String _reqStr(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is String && v.isNotEmpty) return v;
  throw _unexpected();
}

String? _optStr(Map<String, dynamic> m, String key) {
  final v = m[key];
  return v is String ? v : null;
}

DateTime? _optDate(Map<String, dynamic> m, String key) {
  final v = m[key];
  return v is String ? DateTime.tryParse(v) : null;
}

// ---------------------------------------------------------------------------
// Department
// ---------------------------------------------------------------------------
enum DepartmentApiStatus {
  pending,
  inReview,
  cleared,
  actionRequired,
  notRequired,
  unknown,
}

enum DepartmentApplicability { mandatory, notRequired, undetermined, unknown }

DepartmentApiStatus parseApiDepartmentStatus(String? raw) {
  final s = switch (raw) {
    'PENDING' => DepartmentApiStatus.pending,
    'IN_REVIEW' => DepartmentApiStatus.inReview,
    'CLEARED' => DepartmentApiStatus.cleared,
    'ACTION_REQUIRED' => DepartmentApiStatus.actionRequired,
    'NOT_REQUIRED' => DepartmentApiStatus.notRequired,
    _ => DepartmentApiStatus.unknown,
  };
  if (s == DepartmentApiStatus.unknown) {
    debugPrint('Unknown department status received: $raw');
  }
  return s;
}

DepartmentApplicability parseApiApplicability(String? raw) => switch (raw) {
  'REQUIRED' => DepartmentApplicability.mandatory,
  'NOT_REQUIRED' => DepartmentApplicability.notRequired,
  'UNDETERMINED' => DepartmentApplicability.undetermined,
  _ => DepartmentApplicability.unknown,
};

class DepartmentDto {
  const DepartmentDto({
    required this.code,
    required this.displayName,
    required this.applicability,
    required this.status,
    this.remarks,
    this.updatedAt,
  });

  final String code;
  final String displayName;
  final DepartmentApplicability applicability;
  final DepartmentApiStatus status;

  /// Not shown until Student visibility of remarks is confirmed.
  final String? remarks;
  final DateTime? updatedAt;

  factory DepartmentDto.fromJson(dynamic json) {
    final m = _asMap(json);
    final code = _reqStr(m, 'departmentCode');
    return DepartmentDto(
      code: code,
      displayName: _optStr(m, 'displayName') ?? code,
      applicability: parseApiApplicability(_optStr(m, 'applicability')),
      status: parseApiDepartmentStatus(_optStr(m, 'status')),
      remarks: _optStr(m, 'remarks'),
      updatedAt: _optDate(m, 'updatedAt'),
    );
  }
}

List<DepartmentDto> _departments(dynamic v) {
  if (v == null) return const [];
  if (v is! List) throw _unexpected();
  return v.map((e) => DepartmentDto.fromJson(e)).toList();
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------
class StudentProfileDto {
  const StudentProfileDto({required this.sapId, required this.studentName});

  final String sapId;
  final String studentName;

  factory StudentProfileDto.fromJson(dynamic json) {
    final m = _asMap(json);
    return StudentProfileDto(
      sapId: _reqStr(m, 'sapId'),
      studentName: _reqStr(m, 'studentName'),
    );
  }
}

// ---------------------------------------------------------------------------
// Requests
// ---------------------------------------------------------------------------
class StudentRequestSummaryDto {
  const StudentRequestSummaryDto({
    required this.id,
    required this.requestReference,
    required this.reason,
    required this.isActive,
    this.submittedAt,
    this.closedAt,
  });

  /// Internal UUID. Use this (not the reference) for the detail path.
  final String id;
  final String requestReference;
  final String reason;
  final bool isActive;
  final DateTime? submittedAt;
  final DateTime? closedAt;

  factory StudentRequestSummaryDto.fromJson(dynamic json) {
    final m = _asMap(json);
    final isActive = m['isActive'];
    if (isActive is! bool) throw _unexpected();
    return StudentRequestSummaryDto(
      id: _reqStr(m, 'id'),
      requestReference: _reqStr(m, 'requestReference'),
      reason: _reqStr(m, 'reason'),
      isActive: isActive,
      submittedAt: _optDate(m, 'submittedAt'),
      closedAt: _optDate(m, 'closedAt'),
    );
  }
}

class StudentRequestDto {
  const StudentRequestDto({
    required this.summary,
    required this.departments,
    this.sapId,
    this.studentName,
    this.registrationNumber,
    this.fatherName,
    this.program,
    this.semester,
  });

  final StudentRequestSummaryDto summary;
  final List<DepartmentDto> departments;
  final String? sapId;
  final String? studentName;
  final String? registrationNumber;
  final String? fatherName;
  final String? program;
  final String? semester;

  factory StudentRequestDto.fromJson(dynamic json) {
    final m = _asMap(json);
    return StudentRequestDto(
      summary: StudentRequestSummaryDto.fromJson(m),
      departments: _departments(m['departments']),
      sapId: _optStr(m, 'sapId'),
      studentName: _optStr(m, 'studentName'),
      registrationNumber: _optStr(m, 'registrationNumber'),
      fatherName: _optStr(m, 'fatherName'),
      program: _optStr(m, 'program'),
      semester: _optStr(m, 'semester'),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
class StudentDashboardDto {
  const StudentDashboardDto({
    required this.departments,
    required this.closedRequestCount,
    this.profile,
    this.activeRequest,
    this.progress,
    this.latestClosedRequest,
  });

  final StudentProfileDto? profile;
  final StudentRequestSummaryDto? activeRequest;
  final List<DepartmentDto> departments;

  /// Shape not final in the contract. Kept raw, not displayed.
  final Map<String, dynamic>? progress;
  final int closedRequestCount;
  final StudentRequestSummaryDto? latestClosedRequest;

  factory StudentDashboardDto.fromJson(dynamic json) {
    final m = _asMap(json);
    final profile = m['profile'];
    final active = m['activeRequest'];
    final progress = m['progress'];
    final history = m['history'];

    var closedCount = 0;
    StudentRequestSummaryDto? latest;
    if (history != null) {
      final h = _asMap(history);
      final c = h['closedRequestCount'];
      if (c is int) closedCount = c;
      if (h['latestClosedRequest'] != null) {
        latest = StudentRequestSummaryDto.fromJson(h['latestClosedRequest']);
      }
    }

    return StudentDashboardDto(
      profile: profile == null ? null : StudentProfileDto.fromJson(profile),
      activeRequest:
      active == null ? null : StudentRequestSummaryDto.fromJson(active),
      departments: _departments(m['departments']),
      progress:
      progress is Map ? Map<String, dynamic>.from(progress) : null,
      closedRequestCount: closedCount,
      latestClosedRequest: latest,
    );
  }
}