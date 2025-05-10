import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'dart:developer'; 

class AuthService {
  static String? _token;
  static final _secureStorage = const FlutterSecureStorage();

  static Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/user/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];

      // ✅ 기본 토큰 저장 (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);

      // ✅ 선택적으로 SecureStorage에 저장 (바이오 자동 로그인용)
      if (rememberMe) {
        await _secureStorage.write(key: 'bio_token', value: _token!);
      }

      return true;
    } else {
      return false;
    }
  }


  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  /// 바이오 인증 시 사용할 토큰 불러오기
  static Future<String?> getBioToken() async {
    return await _secureStorage.read(key: 'bio_token');
  }

  /// 바이오 인증용 토큰 검증 API
  static Future<bool> verifyBioToken() async {
    final token = await getBioToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/user/me'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      log("Bio token 검증 실패: $e");
      return false;
    }
  }

  /// 로그아웃 시 secureStorage도 삭제
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await _secureStorage.delete(key: 'bio_token');
    _token = null;
  }

  /// 새로운 `getUserId()` - API에서 `user_id` 가져오기
  static Future<String?> getUserId() async {
    String? token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/user/me'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id']; // user_id 반환
      }
    } catch (e) {
      log("Error fetching user ID: $e");
    }
    return null;
  }
}
