// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// **Login: เพิ่มการบันทึก "เวลาล็อกอินล่าสุด"**
  Future<String?> login(String username, String password, String token) async {
    final result = await _apiService.login(username, password, token);

    if (result['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', result['username']);
      await prefs.setString('token_expires_at', result['expires_at']);
      // ✅ บันทึกเวลาที่ล็อกอินสำเร็จ
      await prefs.setString(
          'last_login_timestamp', DateTime.now().toUtc().toIso8601String());
      return null;
    } else {
      return result['message'] ?? 'An unknown error occurred';
    }
  }

  /// **checkSession: ตรวจสอบแค่ Token หมดอายุ (สำหรับตอนเปิดแอป)**
  Future<Map<String, dynamic>> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      return {'loggedIn': false, 'message': 'No token found.'};
    }

    // ตรวจสอบ Token หมดอายุกับ Server ก่อนเสมอ
    final tokenResult = await _apiService.validateToken(token);

    if (!tokenResult.isValid) {
      await logout();
      return {
        'loggedIn': false,
        'message': "โทเค็นของคุณหมดอายุ กรุณาติดต่อผู้พัฒนา"
      };
    }

    // ถ้า Token ยังไม่หมดอายุ ถือว่ายังล็อกอินอยู่
    return {'loggedIn': true, 'message': 'Session is valid.'};
  }

  /// **Logout: ล้างข้อมูลทั้งหมด รวมถึงเวลาล็อกอินล่าสุด**
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('token_expires_at');
    await prefs.remove('last_login_timestamp'); // ✅ ล้างเวลาล็อกอิน
  }

  Future<String?> register(String username, String password) async {
    final result = await _apiService.register(username, password);
    if (result['status'] == 'success') {
      return null;
    } else {
      return result['message'] ?? 'An unknown registration error occurred';
    }
  }
}
