// lib/HomepageApp/auth_wrapper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _expiryCheckTimer;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _initializeAppState();
  }

  @override
  void dispose() {
    _expiryCheckTimer?.cancel();
    super.dispose();
  }

  /// ฟังก์ชันสำหรับตรวจสอบสถานะเริ่มต้นและตั้งค่า Timer
  Future<void> _initializeAppState() async {
    final sessionData = await _authService.checkSession();
    if (mounted) {
      setState(() {
        _isLoggedIn = sessionData['loggedIn'] ?? false;
        _isLoading = false;
      });
      if (_isLoggedIn) {
        _startLocalExpiryCheckTimer();
      }
    }
  }

  /// ฟังก์ชัน "เครื่องตรวจจับชีพจร" ที่ทำงานใน AuthWrapper
  void _startLocalExpiryCheckTimer() {
    _expiryCheckTimer?.cancel();
    // ตั้งเวลาตรวจสอบทุก 15 วินาที
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!mounted || _isDialogShowing) return;

      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString('token_expires_at');

      if (expiryString == null) {
        timer.cancel();
        _handleLogout();
        return;
      }

      final expiryDate = DateTime.tryParse(expiryString);
      if (expiryDate == null) {
        timer.cancel();
        _handleLogout();
        return;
      }

      final nowUtc = DateTime.now().toUtc();
      if (nowUtc.isAfter(expiryDate)) {
        timer.cancel();
        _showExpiredTokenDialog();
      }
    });
  }

  /// ฟังก์ชันสำหรับแสดง Pop-up
  void _showExpiredTokenDialog() {
    if (_isDialogShowing) return;
    setState(() => _isDialogShowing = true);

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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    ).then((_) {
      _handleLogout();
    });
  }

  /// ฟังก์ชันสำหรับจัดการการ Logout
  Future<void> _handleLogout() async {
    _expiryCheckTimer?.cancel();
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _isDialogShowing = false;
      });
    }
  }

  /// ฟังก์ชันสำหรับจัดการเมื่อ Login สำเร็จ
  void _handleLoginSuccess() {
    if (mounted) {
      setState(() {
        _isLoading = true; // แสดง loading ขณะตรวจสอบสถานะใหม่
      });
      _initializeAppState(); // เริ่มกระบวนการตรวจสอบใหม่ทั้งหมด
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return MyHomepage(onLogout: _handleLogout);
    } else {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }
  }
}