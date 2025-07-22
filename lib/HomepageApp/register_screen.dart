// lib/HomepageApp/register_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _performRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // --- เรียกใช้ AuthService ที่แก้ไขแล้ว ---
      final error = await _authService.register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error == null) {
        // --- ถ้าสำเร็จ แสดงข้อความและกลับไปหน้า Login ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'สร้างบัญชีสำเร็จ! กรุณารอ Admin กำหนด Token เพื่อเข้าใช้งาน'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // กลับไปหน้า Login
      } else {
        // --- ถ้าไม่สำเร็จ แสดงข้อความ Error จาก Server ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... โค้ดส่วน UI ของคุณยังคงเหมือนเดิม ไม่ต้องแก้ไข ...
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างบัญชีผู้ใช้')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (value.length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration:
                      const InputDecoration(labelText: 'ยืนยันรหัสผ่าน'),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'รหัสผ่านไม่ตรงกัน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _performRegister,
                          child: const Text('สร้างบัญชี'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
