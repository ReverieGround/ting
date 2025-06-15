import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'feed_unfold_page.dart';
import '../widgets/common/vibe_header.dart'; 
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _rememberMe = false;
  bool _showResendButton = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricLogin();
  }

  Future<void> _tryBiometricLogin() async {
    final hasBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!hasBiometrics || !isDeviceSupported) return;

    final didAuthenticate = await _localAuth.authenticate(
      localizedReason: '바이오 인증으로 자동 로그인',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (didAuthenticate) {
      final success = await AuthService.verifyAuthToken();  // ✅ bio_token 없이 auth_token 하나로 통일
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FeedUnfoldPage()),
        );
      }
    }
  }

  Future<void> login() async {
    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        // ✅ rememberMe 체크된 경우 토큰 저장 (bio login용)
        if (_rememberMe) {
          await AuthService.storeAuthToken();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FeedUnfoldPage()),
        );
      } else {
        await FirebaseAuth.instance.signOut();

        setState(() {
          _showResendButton = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증이 완료되지 않았습니다.\n메일함에서 인증 링크를 확인해주세요.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${e.message ?? '알 수 없는 오류'}')),
      );
    }
  }


  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("인증 메일을 다시 보냈습니다.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("메일 전송에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: VibeHeader(
      //   titleWidget: Text(
      //     '로그인',
      //     style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      //   ),
      //   showBackButton: false,
      // ),
      body:  SafeArea(
      child:  Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Image.asset(
                'assets/vibeyum_logo.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),   
            Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              //   child:  Align(
              //     alignment: Alignment.centerLeft, // ✅ 왼쪽 정렬
              //     child: Text(
              //       'Welcome',
              //       style:TextStyle(
              //         fontSize: 24,
              //         color: const Color.fromARGB(255, 56, 56, 56),
              //         fontWeight: FontWeight.bold,
              //         letterSpacing: -0.5, 
              //         wordSpacing: -1,     
              //       ),
              //     ),
              //   ),
              // ),
              TextField(
                controller: emailController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: 'example@domain.com', // ✅ 힌트 추가
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.grey
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  ),
                  focusedBorder: OutlineInputBorder( // ✅ 포커스 시 검정색 테두리 적용
                    borderSide: BorderSide(color: Colors.black, width: 1.3), 
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                obscureText: false,
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
                    borderSide: BorderSide(color: Colors.black, width: 1.3), 
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                obscureText: true,
              ),
              // SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // ✅ 둥글게
                      ),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4), // ✅ 촘촘하게
                    ),
                    const Text("Remember me", style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(
                      'Forget Password?',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (_showResendButton)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextButton(
                    onPressed: resendVerificationEmail,
                    child: Text('인증 메일 다시 보내기'),
                  ),
                ),
              // 로그인 버튼 (가로 전체 너비)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10), // 버튼 높이 키우기
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10), // 버튼 높이 키우기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              ]
            ),
            // SNS 간편 로그인 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                children: [
                  Text("SNS 계정으로 간편 로그인", style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _snsLoginButton('assets/login_icons/naver_logo.png', '네이버', () {/* TODO: 네이버 로그인 */}),
                      _snsLoginButton('assets/login_icons/kakao_logo.png', '카카오', () {/* TODO: 카카오 로그인 */}),
                      _snsLoginButton(
                        'assets/login_icons/google_logo.png',
                        '구글',
                        () async {
                          final cred = await AuthService.signInWithGoogle(context);
                          if (cred != null) {
                            await AuthService.registerUserInFirestore(
                                username: cred.user?.displayName ?? '',
                                countryCode: 'KR',
                                countryName: 'Korea',
                                profileImageUrl: cred.user?.photoURL,
                              );

                              // ✅ 자동 이동 처리
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const FeedUnfoldPage()),
                              );
                          }
                        },
                      ),
                      _snsLoginButton(
                        'assets/login_icons/facebook_logo.png',
                        '페이스북',
                        () async {
                          final cred = await AuthService.signInWithFacebook();

                          if (cred != null) {
                            await AuthService.registerUserInFirestore(
                              username: cred.user?.displayName ?? '',
                              countryCode: 'KR',
                              countryName: 'Korea',
                              profileImageUrl: cred.user?.photoURL,
                            );

                            // ✅ 로그인 성공 안내
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Facebook 로그인 성공'),
                                duration: Duration(milliseconds: 1000),
                              ),
                            );

                            // ✅ 자동 이동
                            await Future.delayed(const Duration(milliseconds: 1000));
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const FeedUnfoldPage()),
                            );
                          } else {
                            // ✅ 실패 안내
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Facebook 로그인 실패'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical:6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have account?", 
                    style: TextStyle(
                      fontSize: 14, 
                      color: Colors.grey[800]
                      )
                    ),
                  SizedBox(width: 25),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 255, 108, 108),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
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
            radius: 22,
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
