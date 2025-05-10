import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/register/text_field.dart';
import '../widgets/register/country_field.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config.dart';
import 'dart:developer'; 
import '../widgets/utils/profile_avatar.dart';
import '../widgets/common/vibe_header.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController customCountryController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool isRegistering = false;
  bool isCustomCountry = false;

  // ✅ 국가 리스트
  final Map<String, String> countryMap = {
    "KR": "South Korea",
    "US": "United States",
    "JP": "Japan",
    "CN": "China",
    "FR": "France",
    "DE": "Germany",
    "IT": "Italy",
    "BR": "Brazil",
    "GB": "United Kingdom",
    "IN": "India",
    "OTHER": "Other (Enter Manually)", // 직접 입력 옵션
  };

  String? selectedCountryCode;
  String? selectedCountryName;

  /// ✅ 이메일 중복 체크
  Future<bool> checkEmailExists(String email) async {
    final response = await http.get(Uri.parse('${Config.baseUrl}/user/check_email?email=$email'));
    return response.statusCode == 409; // 409이면 중복됨
  }

  /// ✅ 프로필 이미지 업로드 (Firebase Storage)
  Future<String?> uploadProfileImage(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/user/upload_image'));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);
      return jsonResponse['profile_image_url'];
    } else {
      return null;
    }
  }

  bool isValidEmail(String email) {
    return email.contains("@");
  }

  bool isValidPassword(String password) {
    // return RegExp(r'^(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$').hasMatch(password);
    final lowercaseMatches = RegExp(r'[a-z]').allMatches(password).length;
    final numberMatches = RegExp(r'[0-9]').allMatches(password).length;
    return (lowercaseMatches + numberMatches) >= 4;
  }

  /// ✅ 사용자 등록
  Future<void> registerUser() async {
    if (isRegistering) return;
    setState(() => isRegistering = true);

    String email = emailController.text.trim();
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();
    String bio = bioController.text.trim();


    if (!isValidPassword(password)) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('비밀번호는 소문자, 숫자, 특수문자를 포함해야 합니다.')));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('비밀번호는 소문자를 포함해야 합니다.')));
      setState(() => isRegistering = false);
      return;
    }

    String? profileImageUrl;
    if (_profileImage != null) {
      profileImageUrl = await uploadProfileImage(_profileImage!);
    }

    // ✅ 선택한 국가 정보 처리
    String countryCode = selectedCountryCode ?? "CUSTOM";
    String countryName = isCustomCountry ? customCountryController.text.trim() : (selectedCountryName ?? "Unknown");

    final response = await http.post(
      Uri.parse('${Config.baseUrl}/user/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "profile_image": profileImageUrl ?? "",
        "bio": bio,
        "country_code": countryCode,
        "country_name": countryName,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 실패')));
    }

    setState(() => isRegistering = false);
  }

  /// ✅ 갤러리에서 프로필 이미지 선택
  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  bool passwordsMatch() {
    return passwordController.text == confirmPasswordController.text;
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: VibeHeader(
      titleWidget: Text(
        '회원가입',
        style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
    )),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickProfileImage,
                    child: ProfileAvatar(
                        profileImage: _profileImage,
                        size: 80,
                      )
                  ),
                  SizedBox(height: 12),
                  RegisterTextField(
                    controller: emailController,
                    label: '이메일',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "이메일을 입력하세요";
                      }
                      if (!isValidEmail(value)) {
                        return "올바른 이메일 주소를 입력하세요";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  RegisterTextField(
                    controller: usernameController,
                    label: '닉네임',
                    icon: Icons.person_outline),
                  SizedBox(height: 12),
                  RegisterTextField(
                    controller: passwordController,
                    label: '비밀번호',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null) {
                        return "비밀번호를 입력하세요";
                      }
                      if (value.isEmpty) {
                        return null ;
                      }
                      if (!isValidPassword(value)) {
                        // return "비밀번호는 최소 8자, 소문자, 숫자, 특수문자를 포함해야 합니다.";
                        return "비밀번호는 최소 8자, 소문자를 포함해야 합니다.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  RegisterTextField(
                    controller: confirmPasswordController,
                    label: '비밀번호 확인',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null) {
                        return "비밀번호를 다시 입력하세요";
                      }
                      if (value.isEmpty) {
                        return null ;
                      }
                      if (!passwordsMatch()) {
                        return "비밀번호가 일치하지 않습니다";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  RegisterTextField(
                    controller: bioController,
                    label: '소개',
                    icon: Icons.info_outline),
                  SizedBox(height: 12),
                  RegisterCountryField(
                    label: '국가 선택',
                    icon: Icons.public,
                    onCountrySelected: (code, name) {
                      log("선택한 국가: $code - $name");
                    },
                  ),
                ],
              ),
            ),
          ),
          // ✅ 버튼을 하단에 고정하고 넓게 설정
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8), // ✅ 좌우 여백 추가
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16), // 버튼 높이 키우기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isRegistering 
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black), 
                        ) 
                      : Text('회원가입', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

}
