import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Override this string with your PC's IP if testing on a real Android phone (e.g. 'http://192.168.1.5:4000/api/v1')
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api/v1';
    }
    return 'http://localhost:4000/api/v1';
  }
}