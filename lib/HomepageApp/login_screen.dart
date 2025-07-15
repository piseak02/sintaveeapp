import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _performLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final error = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _tokenController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sintavee App', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(labelText: 'Activation Token'),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอก Token' : null,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _performLogin,
                          child: const Text('เข้าสู่ระบบ'),
                        ),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: const Text('ยังไม่มีบัญชี? สร้างบัญชีใหม่'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
