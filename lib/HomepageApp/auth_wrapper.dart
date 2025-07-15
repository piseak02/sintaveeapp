import 'package:flutter/material.dart';
import 'package:sintaveeapp/HomepageApp/my_homepage.dart';
import 'package:sintaveeapp/services/auth_service.dart';
import 'package:sintaveeapp/HomepageApp/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isLoading = false;
      });
    }
  }

  // --- จุดที่แก้ไข ---
  // 1. สร้างฟังก์ชันสำหรับจัดการการ Logout โดยเฉพาะ
  Future<void> _onLogout() async {
    // สั่งให้ AuthService ทำการลบ Token ออกจากเครื่อง
    await _authService.logout();
    // ตรวจสอบสถานะใหม่อีกครั้ง (ซึ่งตอนนี้จะกลายเป็น false แล้ว)
    _checkSession();
  }

  // 2. สร้างฟังก์ชันสำหรับจัดการเมื่อ Login สำเร็จ
  void _onLoginSuccess() {
    _checkSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      // 3. ส่งฟังก์ชัน _onLogout ไปให้ MyHomepage
      return MyHomepage(onLogout: _onLogout);
    } else {
      // 4. ส่งฟังก์ชัน _onLoginSuccess ไปให้ LoginScreen
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }
  }
}
