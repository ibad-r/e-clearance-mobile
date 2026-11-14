import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/student_api_models.dart';

/// Student API calls. Uses the shared ApiClient (Bearer token, 401 handling,
/// error parsing). Paths are relative: ApiConfig.baseUrl already has /api/v1.
class StudentRepository {
  StudentRepository(this._api);

  final ApiClient _api;

  Future<StudentProfileDto> fetchProfile() async {
    final data = await _api.get('/student/profile');
    return StudentProfileDto.fromJson(data);
  }

  Future<StudentDashboardDto> fetchDashboard() async {
    final data = await _api.get('/student/dashboard');
    return StudentDashboardDto.fromJson(data);
  }

  /// Sends exactly the five approved fields. Never sends SAP ID, name,
  /// user id, role, reference or any status: the backend derives them.
  Future<StudentRequestDto> createRequest({
    required String registrationNumber,
    required String fatherName,
    required String program,
    required String semester,
    required String reason,
  }) async {
    final data = await _api.post(
      '/student/requests',
      body: {
        'registrationNumber': registrationNumber.trim(),
        'fatherName': fatherName.trim(),
        'program': program.trim(),
        'semester': semester.trim(),
        'reason': reason,
      },
    );
    return StudentRequestDto.fromJson(data);
  }

  Future<List<StudentRequestSummaryDto>> listRequests() async {
    final data = await _api.get('/student/requests');
    if (data is! List) {
      throw ApiException(message: 'Unexpected response from the server.');
    }
    return data.map((e) => StudentRequestSummaryDto.fromJson(e)).toList();
  }

  /// [requestId] is the internal UUID, not the human-readable reference.
  Future<StudentRequestDto> fetchRequest(String requestId) async {
    final id = requestId.trim();
    if (id.isEmpty) {
      throw ArgumentError('requestId must not be empty');
    }
    final data = await _api.get('/student/requests/${Uri.encodeComponent(id)}');
    return StudentRequestDto.fromJson(data);
  }
}