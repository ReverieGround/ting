import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'dart:developer'; 

class AuthService {
  static String? _token;

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/user/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];

      // 토큰을 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      
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

  /// ✅ 새로운 `getUserId()` - API에서 `user_id` 가져오기
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
        return data['user_id']; // ✅ user_id 반환
      }
    } catch (e) {
      log("Error fetching user ID: $e");
    }
    return null;
  }
}
