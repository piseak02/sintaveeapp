import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert'; // สำหรับ jsonEncode และ jsonDecode
import 'package:http/http.dart' as http; // สำหรับเรียก API
import 'package:device_info_plus/device_info_plus.dart'; // สำหรับดึง Device ID
import 'dart:io'; // สำหรับเช็ค Platform

// --- SERVICE สำหรับจัดการการเชื่อมต่อกับ Backend ---
class ApiService {
  // !!! สำคัญ: นำ URL ของ Web App ที่ได้จาก Google Apps Script มาวางที่นี่ !!!
  static const String _appsScriptUrl =
      'https://script.google.com/macros/s/AKfycbx1CXPJrYK85vFXPOZpkyjg8joU7RbtM1H3Oaha1I99RK0p75_5ufK1G3nHkZsHcg2B9g/exec';

  // ฟังก์ชันดึงรหัสเฉพาะของอุปกรณ์ (Device ID)
  static Future<String?> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // ใช้ ID ที่ไม่ซ้ำกันสำหรับ Android
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // ID เฉพาะสำหรับแอปใน iOS
      }
    } catch (e) {
      print('Failed to get device ID: $e');
    }
    return null;
  }

  // ฟังก์ชันตรวจสอบ Token กับ Backend
  static Future<bool> validateToken(String token) async {
    if (_appsScriptUrl.contains('YOUR_APPS_SCRIPT')) {
      print('ERROR: Please set your Apps Script URL in ApiService.');
      return false;
    }
    final uri = Uri.parse('$_appsScriptUrl?action=validate&token=$token');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Validation Response: $data');
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // ฟังก์ชันขอ Token ใหม่จาก Backend
  static Future<String?> requestNewToken(String type) async {
    if (_appsScriptUrl.contains('YOUR_APPS_SCRIPT')) {
      print('ERROR: Please set your Apps Script URL in ApiService.');
      return null;
    }

    final deviceId = await getDeviceId();
    if (deviceId == null) {
      print('Could not get device ID.');
      return null;
    }

    final uri = Uri.parse(_appsScriptUrl);
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'activate',
              'deviceId': deviceId,
              'type': type,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Activation Response: $data');
        if (data['status'] == 'success') {
          return data['token'];
        }
      }
      return null;
    } catch (e) {
      print('Error requesting token: $e');
      return null;
    }
  }
}

// --- Entry Point ของแอป ---
void main() {
  runApp(const MyApp01());
}

class MyApp01 extends StatelessWidget {
  const MyApp01({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Token Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Widget สำหรับจัดการว่าจะแสดงหน้าไหนระหว่าง Loading, Login, หรือ Home
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      // ตรวจสอบ token กับ backend จริง
      final isValid = await ApiService.validateToken(token);
      if (!isValid) {
        // ถ้า token ไม่ถูกต้องแล้ว ให้ลบออกจากเครื่อง
        await prefs.remove('auth_token');
      }
      setState(() {
        _isLoggedIn = isValid;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoggedIn) {
      return HomeScreen(onLogout: _checkLoginStatus);
    } else {
      // ส่ง callback function ไปเพื่อให้หน้า Login สามารถ trigger การ refresh ได้
      return LoginScreen(onLoginSuccess: _checkLoginStatus);
    }
  }
}

// --- หน้า Login และขอ Token ---
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_tokenController.text.isEmpty) {
      _showSnackBar('กรุณาใส่ Token ของคุณ');
      return;
    }

    setState(() => _isLoading = true);

    final isValid = await ApiService.validateToken(_tokenController.text);

    setState(() => _isLoading = false);

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _tokenController.text);
      widget.onLoginSuccess(); // เรียก callback เพื่อ refresh AuthWrapper
    } else {
      _showSnackBar('Token ไม่ถูกต้องหรือหมดอายุแล้ว');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'เข้าสู่ระบบ',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรุณาใส่ Token เพื่อเข้าใช้งาน',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Activation Token',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            child: const Text('ยืนยัน Token'),
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => ActivationScreen(
                                onActivationSuccess: widget.onLoginSuccess)),
                      );
                    },
                    child: const Text('ยังไม่มี Token? เปิดใช้งานที่นี่'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- หน้าสำหรับขอ Token (ทดลองใช้ / ถาวร) ---
class ActivationScreen extends StatefulWidget {
  final VoidCallback onActivationSuccess;
  const ActivationScreen({super.key, required this.onActivationSuccess});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  bool _isLoading = false;
  String _loadingMessage = 'กำลังสร้าง Token...';

  Future<void> _activate(String type) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'กำลังเชื่อมต่อเซิร์ฟเวอร์...';
    });

    final token = await ApiService.requestNewToken(type);

    setState(() => _isLoading = false);

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('เปิดใช้งานสำเร็จ!'),
            content: SelectableText(
                'Token ของคุณคือ:\n\n$token\n\nกรุณาเก็บ Token นี้ไว้ในที่ปลอดภัย'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                  widget.onActivationSuccess(); // กลับไปหน้าแรกและ refresh
                },
                child: const Text('เข้าสู่ระบบ'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'เกิดข้อผิดพลาด: ไม่สามารถสร้าง Token ได้ หรืออุปกรณ์นี้เคยลงทะเบียนแล้ว'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เปิดใช้งาน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_loadingMessage),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'เลือกรูปแบบการใช้งาน',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.timer_outlined),
                          label: const Text('ทดลองใช้ 30 วัน'),
                          onPressed: () => _activate('trial'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_user),
                          label: const Text('เปิดใช้งานถาวร'),
                          onPressed: () => _activate('permanent'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- หน้าหลักของแอป (แสดงหลัง Login สำเร็จ) ---
class HomeScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    onLogout(); // เรียก callback เพื่อ refresh AuthWrapper
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'ออกจากระบบ',
          )
        ],
      ),
      body: const Center(
        child: Text(
          'ยินดีต้อนรับ! คุณเข้าสู่ระบบสำเร็จแล้ว',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

/*
--- Dependencies ที่ต้องเพิ่มใน pubspec.yaml ---

dependencies:
  flutter:
    sdk: flutter
  
  # สำหรับการจัดเก็บข้อมูลในเครื่อง
  shared_preferences: ^2.2.3 

  # สำหรับเรียก API (Backend)
  http: ^1.2.1

  # สำหรับดึงรหัสเฉพาะของเครื่อง
  device_info_plus: ^10.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
*/
