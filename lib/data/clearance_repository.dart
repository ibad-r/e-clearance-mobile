import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/clearance_request.dart';

abstract class ClearanceRepository {
  Future<ClearanceRequest> submit(ClearanceDraft draft);
  Future<List<ClearanceRequest>> listCases();
  Future<ClearanceRequest> getCase(String caseId);
}

class ApiClearanceRepository implements ClearanceRepository {
  ApiClearanceRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<ClearanceRequest> submit(ClearanceDraft draft) async {
    final day = draft.lastWorkingDay;
    final reason = draft.reason?.trim() ?? '';
    final remarks = draft.remarks.trim();

    if (day == null) {
      throw _invalid('Please choose your last working day.');
    }
    if (reason.length < 3 || reason.length > 500) {
      throw _invalid('Reason for leaving must be 3 to 500 characters.');
    }
    if (remarks.length > 1000) {
      throw _invalid('Remarks must be at most 1000 characters.');
    }

    // Exactly the three fields the backend accepts. Nothing else is sent.
    final data = await _api.post('/employee/cases', body: {
      'lastWorkingDate': _isoDate(day),
      'reasonForLeaving': reason,
      'employeeRemarks': remarks.isEmpty ? null : remarks,
    });
    return _parseCase(data);
  }

  @override
  Future<List<ClearanceRequest>> listCases() async {
    final data = await _api.get('/employee/cases');
    if (data is! List) throw _unexpected();
    return data.map(_parseCase).toList();
  }

  @override
  Future<ClearanceRequest> getCase(String caseId) async {
    final data = await _api.get('/employee/cases/$caseId');
    return _parseCase(data);
  }

  ClearanceRequest _parseCase(dynamic data) {
    if (data is! Map) throw _unexpected();
    try {
      return ClearanceRequest.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      throw _unexpected();
    }
  }

  ApiException _unexpected() =>
      ApiException(message: 'Unexpected response from the server.');

  ApiException _invalid(String message) =>
      ApiException(message: message, statusCode: 422, code: 'VALIDATION_ERROR');

  String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}