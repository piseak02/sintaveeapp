// lib/HomepageApp/auth_wrapper.dart

import 'dart:async'; // Import 'dart:async' เพื่อใช้งาน Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import SharedPreferences
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
  late Future<Map<String, dynamic>> _sessionFuture;
  bool _isExpiredDialogShowing = false;

  Timer? _expiryCheckTimer;

  @override
  void initState() {
    super.initState();
    // ตรวจสอบครั้งแรกเมื่อเปิดแอป
    _sessionFuture = _authService.checkSession();
    // หลังจากตรวจสอบครั้งแรกแล้ว, ให้เริ่ม Timer ถ้าล็อกอินสำเร็จ
    _sessionFuture.then((sessionData) {
      if (sessionData['loggedIn'] == true && mounted) {
        _startLocalExpiryCheckTimer();
      }
    });
  }

  @override
  void dispose() {
    _expiryCheckTimer?.cancel();
    super.dispose();
  }

  /// ✅ --- ส่วนที่อัปเกรดใหม่ทั้งหมด ---
  /// ฟังก์ชันสำหรับเริ่ม Timer ที่จะ "ตรวจสอบเวลาในเครื่อง"
  void _startLocalExpiryCheckTimer() {
    _expiryCheckTimer?.cancel();

    // ตั้งเวลาตรวจสอบทุก 10 วินาที (เพื่อให้ทดสอบได้ง่าย)
    _expiryCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted || _isExpiredDialogShowing) {
        timer.cancel();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString('token_expires_at');

      if (expiryString == null) {
        // ถ้าไม่มีเวลาหมดอายุบันทึกไว้ ให้ทำการ Logout
        timer.cancel();
        _onLogout();
        return;
      }

      final expiryDate = DateTime.tryParse(expiryString);
      if (expiryDate == null) {
        // ถ้ารูปแบบเวลาผิดพลาด ให้ทำการ Logout
        timer.cancel();
        _onLogout();
        return;
      }

      // ✅ --- หัวใจหลัก ---
      // เปรียบเทียบเวลาหมดอายุกับเวลาปัจจุบันของเครื่อง
      if (DateTime.now().isAfter(expiryDate)) {
        // 1. หยุด Timer ทันที
        timer.cancel();
        // 2. แสดง Pop-up แจ้งเตือนโดยตรง
        _showExpiredTokenDialog(context);
      }
    });
  }

  Future<void> _onLogout() async {
    _expiryCheckTimer?.cancel();
    await _authService.logout();
    _refreshSessionUI();
  }

  // ฟังก์ชันสำหรับ Refresh UI หลังจาก Login/Logout
  void _refreshSessionUI() {
    if (mounted) {
      setState(() {
        _isExpiredDialogShowing = false;
        // ทำการตรวจสอบและตั้งค่า Timer ใหม่อีกครั้ง
        _sessionFuture = _authService.checkSession();
        _sessionFuture.then((sessionData) {
          if (sessionData['loggedIn'] == true && mounted) {
            _startLocalExpiryCheckTimer();
          }
        });
      });
    }
  }

  void _showExpiredTokenDialog(BuildContext context) {
    if (_isExpiredDialogShowing) return;

    if (mounted) {
      setState(() {
        _isExpiredDialogShowing = true;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("แจ้งเตือน"),
          content: const Text("โทเค็นของคุณหมดอายุ กรุณาติดต่อผู้พัฒนา"),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // เมื่อผู้ใช้กด "ตกลง" ให้ทำการ Logout
      _onLogout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final bool isLoggedIn = snapshot.data?['loggedIn'] ?? false;

        if (isLoggedIn) {
          return MyHomepage(onLogout: _onLogout);
        } else {
          return LoginScreen(onLoginSuccess: _refreshSessionUI);
        }
      },
    );
  }
}
