// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'device_info_service.dart'; // <<<< Import ที่สร้างขึ้นมาใหม่

class AuthService {
  final ApiService _apiService = ApiService();

  Future<String?> login(String username, String password, String token) async {
    // ✅ ดึง Device ID จากเครื่อง
    final deviceId = await DeviceInfoService.getDeviceId();
    if (deviceId == null) {
      return 'ไม่สามารถดึงข้อมูลเครื่องได้ กรุณาตรวจสอบการอนุญาตของแอป';
    }

    // ✅ ส่ง deviceId ไปกับ request
    final result = await _apiService.login(username, password, token, deviceId);

    if (result['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', result['username']);
      await prefs.setString('token_expires_at', result['expires_at']);
      // ✅ บันทึก deviceId ที่ใช้ล็อกอินสำเร็จ
      await prefs.setString('device_id', deviceId);
      await prefs.setString(
          'last_login_timestamp', DateTime.now().toUtc().toIso8601String());
      return null;
    } else {
      return result['message'] ?? 'An unknown error occurred';
    }
  }

  Future<Map<String, dynamic>> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // ✅ ดึง deviceId ที่บันทึกไว้ในเครื่อง
    final storedDeviceId = prefs.getString('device_id');

    if (token == null || storedDeviceId == null) {
      return {'loggedIn': false, 'message': 'No token or device info found.'};
    }

    // ✅ ส่ง deviceId ที่บันทึกไว้ไปตรวจสอบ
    final tokenResult = await _apiService.validateToken(token, storedDeviceId);

    if (!tokenResult.isValid) {
      await logout();
      return {'loggedIn': false, 'message': tokenResult.message};
    }

    return {'loggedIn': true, 'message': 'Session is valid.'};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('token_expires_at');
    await prefs.remove('last_login_timestamp');
    // ✅ ล้าง deviceId ตอน logout ด้วย
    await prefs.remove('device_id');
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
