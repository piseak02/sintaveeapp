// lib/HomepageApp/auth_wrapper.dart

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

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _authService.checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final bool isLoggedIn = snapshot.data?['loggedIn'] ?? false;

        if (isLoggedIn) {
          return MyHomepage(onLogout: _refresh);
        } else {
          return LoginScreen(onLoginSuccess: _refresh);
        }
      },
    );
  }
}
