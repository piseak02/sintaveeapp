import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sintaveeapp/Database/user_model.dart';
import 'api_service.dart';

class AuthService {
  // --- จุดที่แก้ไข ---
  // ใช้ getter เพื่อ "ดึง" box ที่เปิดไว้แล้วใน main.dart มาใช้งาน
  // วิธีนี้ทำให้มั่นใจว่าจะไม่มีการเรียก openBox() ซ้ำซ้อน
  Box<UserModel> get _userBox => Hive.box<UserModel>('users');

  final ApiService _apiService = ApiService();

  /// ตรวจสอบสถานะการล็อกอินจาก SharedPreferences
  /// โดยเช็คจาก Token และวันหมดอายุ
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final expiresAtStr = prefs.getString('token_expires_at');

    if (token == null) return false;

    // กรณี Token ไม่มีวันหมดอายุ (ถาวร)
    if (expiresAtStr == null || expiresAtStr.isEmpty) {
      return true;
    }

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return false; // รูปแบบวันที่ไม่ถูกต้อง

    // เช็คว่าเวลายังไม่หมดอายุ
    return DateTime.now().isBefore(expiresAt);
  }

  /// ลงทะเบียนผู้ใช้ใหม่ โดยบันทึกลง Hive
  Future<String?> register(String username, String password) async {
    // ใช้ _userBox ที่ดึง box มาแล้วโดยตรง
    if (_userBox.values.any((user) => user.username == username)) {
      return 'ชื่อผู้ใช้นี้มีอยู่แล้ว';
    }
    final newUser = UserModel(username: username, password: password);
    await _userBox.add(newUser);
    return null;
  }

  /// เข้าสู่ระบบ ตรวจสอบข้อมูลผู้ใช้กับ Hive และ Token กับ API
  Future<String?> login(String username, String password, String token) async {
    // ใช้ _userBox ที่ดึง box มาแล้วโดยตรง
    final user = _userBox.values.firstWhere(
      (user) => user.username == username && user.password == password,
      // สร้าง UserModel ว่างๆ กรณีไม่เจอผู้ใช้ เพื่อให้โค้ดไม่พัง
      orElse: () => UserModel(username: '', password: ''),
    );

    if (user.username.isEmpty) {
      return 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
    }

    // ตรวจสอบ Token กับ API
    final tokenResult = await _apiService.validateToken(token);
    if (!tokenResult.isValid) {
      return tokenResult.message;
    }

    // บันทึก Token และวันหมดอายุลง SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('token_expires_at', tokenResult.expiresAt ?? '');

    return null; // คืนค่า null หมายถึง Login สำเร็จ
  }

  /// ออกจากระบบ โดยการลบข้อมูล Token ออกจาก SharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expires_at');
  }
}
