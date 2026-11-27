import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/clearance_request.dart';
import '../models/department_questionnaire.dart';

abstract class ClearanceRepository {
  Future<ClearanceRequest> submit(
      ClearanceDraft draft, {
        Map<String, QuestionAnswer>? questionnaireAnswers,
      });
  Future<List<ClearanceRequest>> listCases();
  Future<ClearanceRequest> getCase(String caseId);
}

class ApiClearanceRepository implements ClearanceRepository {
  ApiClearanceRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<ClearanceRequest> submit(
      ClearanceDraft draft, {
        Map<String, QuestionAnswer>? questionnaireAnswers,
      }) async {
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

    // The backend requires all 14 answers. Never send a partial set and
    // never fill an unanswered question with a default.
    if (questionnaireAnswers != null) {
      final keys = questionnaireAnswers.keys.toSet();
      if (keys.length != kQuestionnaireApiKeys.length ||
          !keys.containsAll(kQuestionnaireApiKeys)) {
        throw _invalid('Please answer all 14 questions.');
      }
    }

    // Only these fields are sent. No IDs, statuses, recommendations or
    // department assignments: the server derives them.
    final body = <String, dynamic>{
      'lastWorkingDate': _isoDate(day),
      'reasonForLeaving': reason,
      'employeeRemarks': remarks.isEmpty ? null : remarks,
    };
    if (questionnaireAnswers != null) {
      body['questionnaireAnswers'] = {
        for (final e in questionnaireAnswers.entries) e.key: e.value.apiValue,
      };
    }

    final data = await _api.post('/employee/cases', body: body);
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