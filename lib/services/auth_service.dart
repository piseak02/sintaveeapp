// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// **Login: ตรวจสอบกับ Server โดยตรง**
  Future<String?> login(String username, String password, String token) async {
    final result = await _apiService.login(username, password, token);

    if (result['status'] == 'success') {
      // Login สำเร็จ, บันทึก session ลง SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', result['username']);
      await prefs.setString('token_expires_at', result['expires_at']);
      return null; // คืนค่า null = สำเร็จ
    } else {
      // Login ไม่สำเร็จ, คืนค่า error message จาก Server
      return result['message'] ?? 'An unknown error occurred';
    }
  }

  /// **Register: ส่งข้อมูลไปสร้างผู้ใช้ใหม่ที่ Server**
  Future<String?> register(String username, String password) async {
    final result = await _apiService.register(username, password);

    if (result['status'] == 'success') {
      return null; // คืนค่า null = สำเร็จ
    } else {
      // คืนค่า error message จาก Server
      return result['message'] ?? 'An unknown registration error occurred';
    }
  }

  /// **checkSession: ตรวจสอบ Session กับ Server**
  Future<Map<String, dynamic>> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      return {'loggedIn': false, 'message': 'No token found.'};
    }

    // ตรวจสอบ token กับ server ทุกครั้ง
    final tokenResult = await _apiService.validateToken(token);

    if (tokenResult.isValid) {
      return {'loggedIn': true, 'message': tokenResult.message};
    } else {
      // ถ้า token ไม่ผ่านการตรวจสอบ (หมดอายุ/ไม่ถูกต้อง) ให้ลบ session ทิ้ง
      await logout();
      return {'loggedIn': false, 'message': tokenResult.message};
    }
  }

  /// **Logout: ล้างข้อมูลออกจาก SharedPreferences**
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('token_expires_at');
  }
}
