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
  bool _autoBioChecked = false;

  @override
  void initState() {
    super.initState();
    _prepareAutoBiometric(); // ✅ 콜드스타트 대비: 조건 만족 시에만 post-frame으로 인증 시도
  }
  
  Future<void> _prepareAutoBiometric() async {
    try {
      // 1) 예전에 로그인한 적 있는지 (flutter_secure_storage / shared_prefs 등)
      final hasLoginBefore = await _authService.hasLoginBefore(); // ex) secure storage bool
      if (!hasLoginBefore) return;

      // 2) 저장된 토큰이 있는지 (단순 존재 여부; 유효성은 아래 verify에서 검사)
      final hasStoredToken = await _authService.hasStoredIdToken();
      if (!hasStoredToken) return;

      // 3) 바이오메트릭 가능/지원 여부
      final hasBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!hasBiometrics || !isSupported) return;

      // ✅ 모든 조건 OK → UI가 그려진 뒤에 트리거 (콜드스타트 초기화 경합 방지)
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_autoBioChecked) {
          _autoBioChecked = true;
          _tryBiometricLogin();
        }
      });
    } catch (e) {
      debugPrint('prepare auto biometric failed: $e');
    }
  }

  // 기존 _tryBiometricLogin는 그대로 두되, 예외 케이스만 조금 더 안전하게 처리
  Future<void> _tryBiometricLogin() async {
    try {
      // 여기선 다시 한 번만 가벼운 가드(중복 방지)
      final hasBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!hasBiometrics || !isSupported) return;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: '바이오 인증으로 자동 로그인',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!didAuthenticate) return;

      // 저장된 토큰의 유효성 검증 (만료/폐기면 false)
      final success = await _authService.verifyStoredIdToken();
      if (!success) return;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on PlatformException catch (e) {
      // NotEnrolled / PasscodeNotSet / NotAvailable 등은 조용히 무시
      debugPrint('biometric error: $e');
    } catch (e) {
      debugPrint('biometric login failed: $e');
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
                          await _authService.markHasLoginBefore();
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
