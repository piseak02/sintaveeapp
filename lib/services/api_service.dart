// lib/services/api_service.dart

import 'package:dio/dio.dart';
import '../models/token_result.dart';

class ApiService {
  final Dio _dio = Dio();
  static const String _appsScriptUrl =
      "https://script.google.com/macros/s/AKfycbzHymnE70lFzbW9CSUUYUjlsXBCdiqaWErni-sb_Sj6SJXRbp-7abThSgtoXNWl46EB/exec";

  // ✅ แก้ไขฟังก์ชัน login ให้รับ deviceId
  Future<Map<String, dynamic>> login(
      String username, String password, String token, String deviceId) async {
    try {
      final uri = Uri.parse(_appsScriptUrl).replace(queryParameters: {
        'action': 'login',
        'username': username,
        'password': password,
        'token': token,
        'deviceId': deviceId, // <<<< เพิ่ม deviceId
      });
      final response = await _dio.get(uri.toString());
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {
        'status': 'error',
        'message': 'Server error: ${response.statusCode}'
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String password) async {
    try {
      final uri = Uri.parse(_appsScriptUrl).replace(queryParameters: {
        'action': 'registerUser',
        'username': username,
        'password': password,
      });
      final response = await _dio.get(uri.toString());
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {
        'status': 'error',
        'message': 'Server error: ${response.statusCode}'
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  /// ✅ แก้ไขฟังก์ชัน validateToken ให้รับและส่ง deviceId
  Future<TokenResult> validateToken(String token, String deviceId) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(_appsScriptUrl).replace(queryParameters: {
        'action': 'validateToken',
        'token': token,
        'deviceId': deviceId, // <<<< เพิ่ม deviceId
        'timestamp': timestamp,
      });

      final response = await _dio.get(
        uri.toString(),
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data;
        return TokenResult(
          isValid: data['isValid'] ?? false,
          message: data['message'] ?? 'Unknown validation error.',
          expiresAt: data['expires_at'],
        );
      }
      return TokenResult(
          isValid: false, message: 'Server error: ${response.statusCode}');
    } catch (e) {
      return TokenResult(
          isValid: false, message: 'Connection error: ${e.toString()}');
    }
  }
}
