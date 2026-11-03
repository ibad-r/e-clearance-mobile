import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/employee_profile.dart';

class ProfileRepository {
  ProfileRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<EmployeeProfile> getProfile() async {
    final data = await _api.get('/employee/profile');
    if (data is! Map) {
      throw ApiException(message: 'Unexpected response from the server.');
    }
    return EmployeeProfile.fromJson(Map<String, dynamic>.from(data));
  }
}