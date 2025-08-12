import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/AuthService.dart';
import '../home/HomePage.dart';
import 'package:flutter/services.dart' show PlatformException;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();  
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricLogin();
  }
  
  Future<void> _tryBiometricLogin() async {
    try {
      final hasBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!hasBiometrics || !isSupported) return;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: '바이오 인증으로 자동 로그인',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true, // 앱 전환 등 상황에서 인증 유지 도움
        ),
      );
      if (!didAuthenticate) return;

      final success = await _authService.verifyStoredIdToken(); // ✅ 저장된 토큰 vs 현재 토큰
      if (!success) return;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on PlatformException catch (e) {
      debugPrint('biometric error: $e');
    } catch (e) {
      debugPrint('biometric login failed: $e');
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final ok = await _authService.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? "인증 메일을 다시 보냈습니다." : "로그인이 필요합니다.")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("메일 전송 실패: ${e.message ?? '알 수 없는 오류'}")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("메일 전송에 실패했습니다.")),
      );
    }
  } 
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
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
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 180,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/title_logo.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "전 세계의 맛있는 순간을",
                      style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                    const Text(
                      "함께 기록해요",
                      style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // SNS 로그인 버튼들
              Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _snsLoginButton(
                      'assets/login_icons/google_logo.png',
                      'Google',
                      () async {
                        final cred = await _authService.signInWithGoogle();
                        if (cred != null) {
                          await _authService.registerUser(
                            userName: cred.user?.displayName ?? '',
                            countryCode: 'KR',
                            countryName: 'Korea',
                            profileImageUrl: cred.user?.photoURL,
                          );
                          await _authService.saveIdToken();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google 로그인 실패')),
                          );
                        }
                      },
                      Colors.white,
                      const Color.fromRGBO(194, 194, 194, 1),
                    ),

                    _snsLoginButton(
                      'assets/login_icons/facebook_logo.png',
                      '페이스북',
                      () async {
                        final cred = await _authService.signInWithFacebook();
                        if (cred != null) {
                          await _authService.registerUser(
                            userName: cred.user?.displayName ?? '',
                            countryCode: 'KR',
                            countryName: 'Korea',
                            profileImageUrl: cred.user?.photoURL,
                          );
                          await _authService.saveIdToken();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Facebook 로그인 성공'), duration: Duration(milliseconds: 1000)),
                          );
                          await Future.delayed(const Duration(milliseconds: 800));
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Facebook 로그인 실패')),
                          );
                        }
                      },
                      Colors.white,
                      const Color.fromRGBO(194, 194, 194, 1),
                    ),

                    _snsLoginButton(
                      'assets/login_icons/naver_logo.png',
                      '네이버',
                      () async {
                        final cred = await _authService.signInWithNaver();
                        if (cred == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('네이버 로그인 준비 중입니다')),
                          );
                          return;
                        }
                        await _authService.registerUser(
                          userName: cred.user?.displayName ?? '',
                          countryCode: 'KR',
                          countryName: 'Korea',
                          profileImageUrl: cred.user?.photoURL,
                        );
                        await _authService.saveIdToken();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      },
                      const Color.fromARGB(255, 7, 199, 71),
                      Colors.white,
                    ),

                    _snsLoginButton(
                      'assets/login_icons/kakao_logo.png',
                      '카카오',
                      () async {
                        final cred = await _authService.signInWithKakao();
                        if (cred == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('카카오 로그인 준비 중입니다')),
                          );
                          return;
                        }
                        await _authService.registerUser(
                          userName: cred.user?.displayName ?? '',
                          countryCode: 'KR',
                          countryName: 'Korea',
                          profileImageUrl: cred.user?.photoURL,
                        );
                        await _authService.saveIdToken();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      },
                      const Color.fromARGB(255, 255, 222, 8),
                      Colors.white,
                    ),
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
