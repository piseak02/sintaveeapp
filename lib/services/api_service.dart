// lib/services/api_service.dart

import 'package:dio/dio.dart';
import '../models/token_result.dart';

class ApiService {
  final Dio _dio = Dio();
  // **สำคัญ: ตรวจสอบให้แน่ใจว่า URL นี้เป็นของคุณ**
  static const String _appsScriptUrl =
      "https://script.google.com/macros/s/AKfycbyUJ3GD-2Kb_9X0IQGZzTiKtJWNhHzLj_hLgNUOn2ULk8SoiOi8rfp2aHnHZkMcLZMFBQ/exec";

  // ... ฟังก์ชัน login และ register ของคุณ ...
  Future<Map<String, dynamic>> login(
      String username, String password, String token) async {
    // ... โค้ดเดิม ...
    try {
      final uri = Uri.parse(_appsScriptUrl).replace(queryParameters: {
        'action': 'login',
        'username': username,
        'password': password,
        'token': token,
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
    // ... โค้ดเดิม ...
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

  /// **ฟังก์ชัน validateToken (เวอร์ชันสุดท้าย - Cache Busting)**
  /// เพิ่ม timestamp ที่ไม่ซ้ำกันใน URL เพื่อป้องกันการ Cache ทุกรูปแบบ
  Future<TokenResult> validateToken(String token) async {
    try {
      // ✅ สร้าง timestamp ที่ไม่ซ้ำกันสำหรับทุกครั้งที่เรียกใช้
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final uri = Uri.parse(_appsScriptUrl).replace(queryParameters: {
        'action': 'validateToken',
        'token': token,
        'timestamp': timestamp, // ✅ เพิ่ม timestamp เข้าไปใน URL
      });

      // เพิ่ม Options เพื่อบังคับให้ดึงข้อมูลใหม่เสมอ
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
