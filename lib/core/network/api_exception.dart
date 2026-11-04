class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400 || statusCode == 422;
  bool get isServerError => (statusCode ?? 0) >= 500;
  bool get isActiveCaseExists => code == 'ACTIVE_CASE_EXISTS';

  factory ApiException.network(String message) =>
      ApiException(message: message);

  factory ApiException.fromResponse(int status, dynamic body) {
    String? code;
    String? message;
    Map<String, dynamic>? details;

    if (body is Map && body['error'] is Map) {
      final err = body['error'] as Map;
      code = err['code']?.toString();
      message = err['message']?.toString();
      if (err['details'] is Map) {
        details = Map<String, dynamic>.from(err['details'] as Map);
      }
    }

    return ApiException(
      message: message ?? _defaultMessage(status),
      statusCode: status,
      code: code,
      details: details,
    );
  }

  static String _defaultMessage(int status) {
    switch (status) {
      case 400:
      case 422:
        return 'Some of the information is not valid. Please check and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to do this.';
      case 404:
        return 'The requested record was not found.';
      case 409:
        return 'This action conflicts with an existing request.';
      default:
        return status >= 500
            ? 'Server error. Please try again later.'
            : 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}