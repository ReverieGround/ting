import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../signup/page.dart';
import '../services/auth_service.dart';
import '../home/page.dart';

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
          // MaterialPageRoute(builder: (context) => const FeedUnfoldPage()),
          MaterialPageRoute(builder: (context) => const MainPage()),
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
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            _showResendButton = true;
          });
        }
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
      body:  SafeArea(
      child:  Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  SizedBox(height: 20),
                  Container(
                    // color: Colors.amber,
                    width: 180,
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/title_logo.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
              
                    ),
                  ),  
                  SizedBox(height: 30),
                  Text("전 세계의 맛있는 순간을", 
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                  )),
                  Text("함께 기록해요",
                    style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  )),
                ]),
            ),
            // SNS 간편 로그인 버튼들
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _snsLoginButton(
                    'assets/login_icons/google_logo.png',
                    'Google',
                    () async {
                      final cred = await AuthService.signInWithGoogle(context);
                      if (cred != null) {
                        await AuthService.registerUserInFirestore(
                            userName: cred.user?.displayName ?? '',
                            countryCode: 'KR',
                            countryName: 'Korea',
                            profileImageUrl: cred.user?.photoURL,
                          );
              
                          // ✅ 자동 이동 처리
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainPage()),
                          );
                      }
                    },
                    Colors.white,
                    Color.fromRGBO(194, 194, 194, 1)
                  ),
                  _snsLoginButton(
                    'assets/login_icons/facebook_logo.png',
                    '페이스북',
                    () async {
                      final cred = await AuthService.signInWithFacebook();
              
                      if (cred != null) {
                        await AuthService.registerUserInFirestore(
                          userName: cred.user?.displayName ?? '',
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
                          MaterialPageRoute(builder: (_) => const MainPage()),
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
                    Colors.white,
                    Color.fromRGBO(194, 194, 194, 1)
                  ),
              
                  _snsLoginButton(
                    'assets/login_icons/naver_logo.png', 
                    '네이버', 
                    () {/* TODO: 네이버 로그인 */}, 
                    const Color.fromARGB(255, 7, 199, 71),
                    Colors.white,
                  ),
                  _snsLoginButton(
                    'assets/login_icons/kakao_logo.png', 
                    '카카오', 
                    () {/* TODO: 카카오 로그인 */}, 
                    Color.fromARGB(255, 255, 222, 8),
                    Colors.white
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    },
                    child: Container(
                      // color: Colors.blue,
                      margin: EdgeInsets.only(top: 24),
                      child: Text(
                        '이메일로 로그인',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black38,
                          fontWeight: FontWeight.bold,
                        ),
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
  Widget _snsLoginButton(String assetPath, String label, VoidCallback onTap, Color backgroundColor, Color borderColor) {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(
          color: borderColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
        color: backgroundColor
      ),
      child: GestureDetector(
        onTap: onTap, // Disable tap if not active
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage: AssetImage(assetPath),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              // width: 200,
              child: Text(
                label+"로 시작하기",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black, // Adjust text color as well
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
