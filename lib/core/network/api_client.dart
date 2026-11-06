import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
  })  : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _http;
  final String baseUrl;
  final Duration timeout;

  /// Login token. Set after login, cleared on logout.
  String? authToken;

  /// Called when the server says the session expired (401).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> _send(
      String method,
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (method == 'POST') 'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final http.Response response;
    try {
      final request = method == 'GET'
          ? _http.get(uri, headers: headers)
          : _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      response = await request.timeout(timeout);
    } on TimeoutException {
      throw ApiException.network(
          'The server took too long to respond. Please try again.');
    } on SocketException {
      throw ApiException.network(
          'Cannot reach the server. Check your connection and try again.');
    } on http.ClientException {
      throw ApiException.network(
          'Cannot reach the server. Check your connection and try again.');
    }

    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      // The backend wraps successful answers as { "data": ... }
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    if (status == 401 && authToken != null) {
      onUnauthorized?.call();
    }
    throw ApiException.fromResponse(status, decoded);
  }
}