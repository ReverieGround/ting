import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'feed_page.dart';
import 'register_page.dart';
import 'feed_unfold_page.dart';
import '../widgets/common/vibe_header.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    bool success = await AuthService.login(emailController.text, passwordController.text);
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FeedUnfoldPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VibeHeader(
        titleWidget: Text(
          '로그인',
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      )),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ 이메일 입력 필드
              TextField(
                controller: emailController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  labelText: '이메일',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.grey
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  ),
                  focusedBorder: OutlineInputBorder( // ✅ 포커스 시 검정색 테두리 적용
                    borderSide: BorderSide(color: Colors.black, width: 1.5), 
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              SizedBox(height: 12),
              // ✅ 비밀번호 입력 필드
              TextField(
                controller: passwordController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.grey
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  ),
                  focusedBorder: OutlineInputBorder( // ✅ 포커스 시 검정색 테두리 적용
                    borderSide: BorderSide(color: Colors.black, width: 1.5), 
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              // ✅ 로그인 버튼 (가로 전체 너비)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12), // 버튼 높이 키우기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              ]
            ),
            SizedBox(height: 24),

            // ✅ SNS 간편 로그인 버튼들
            Text("SNS 계정으로 간편 로그인", style: TextStyle(fontSize: 16, color: Colors.black)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _snsLoginButton('assets/login_icons/naver_logo.png', '네이버', () {/* TODO: 네이버 로그인 */}),
                _snsLoginButton('assets/login_icons/kakao_logo.png', '카카오', () {/* TODO: 카카오 로그인 */}),
                _snsLoginButton('assets/login_icons/google_logo.png', '구글', () {/* TODO: 구글 로그인 */}),
                _snsLoginButton('assets/login_icons/facebook_logo.png', '페이스북', () {/* TODO: 페이스북 로그인 */}),
              ],
            ),
            SizedBox(height: 20),

            // ✅ 간편 회원가입 버튼 (가로 전체 너비)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('간편 회원가입 하기', style: TextStyle(fontSize: 16, color: Colors.black)),
              ),
            ),
            Spacer(), // ✅ 아래쪽 여백 자동 조정

            // ✅ "아이디 찾기 / 비밀번호 찾기"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('아이디 찾기', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                SizedBox(width: 20),
                Text('비밀번호 찾기', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
            SizedBox(height: 20), // ✅ 하단 여백 추가
          ],
        ),
      ),
    );
  }

  // ✅ SNS 로그인 버튼 위젯
  Widget _snsLoginButton(String assetPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: AssetImage(assetPath),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }
}
