import 'package:dio/dio.dart';
import '../models/token_result.dart';

class ApiService {
  final Dio _dio = Dio();
  // URL ของ Google Apps Script
  static const String _appsScriptUrl =
      "https://script.google.com/macros/s/AKfycbyiZ70h5JX_nzylBun20lFs54XlFByoR4mvnSm_oMz94veGB4p5uBk19WbmMki-XRhpGw/exec";

  Future<TokenResult> validateToken(String token) async {
    try {
      final uri = Uri.parse(_appsScriptUrl).replace(queryParameters: {
        'action': 'validate',
        'token': token,
      });

      final response = await _dio.get(uri.toString());

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return TokenResult(
            isValid: true,
            message: data['message'],
            tokenStatus: data['token_status'],
            expiresAt: data['expires_at'],
          );
        } else {
          return TokenResult(
              isValid: false, message: data['message'] ?? 'Invalid token');
        }
      }
      return TokenResult(
          isValid: false, message: 'Server error: ${response.statusCode}');
    } catch (e) {
      return TokenResult(
          isValid: false, message: 'Connection error: ${e.toString()}');
    }
  }
}
