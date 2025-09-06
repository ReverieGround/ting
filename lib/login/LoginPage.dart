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
    _prepareAutoBiometric();
  }
  
  Future<void> _prepareAutoBiometric() async {
    try {
      final hasLoginBefore = await _authService.hasLoginBefore();
      if (!hasLoginBefore) return;

      final hasStoredToken = await _authService.hasStoredIdToken();
      if (!hasStoredToken) return;

      final hasBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!hasBiometrics || !isSupported) return;

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

  Future<void> _tryBiometricLogin() async {
    try {
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

      final success = await _authService.verifyStoredIdToken();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTitle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500);
    final borderColor = theme.dividerColor;
    final labelColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      width: 120,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/logo_white.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("전 세계의 맛있는 순간을", style: textTitle),
                    Text("함께 기록해요", style: textTitle),
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
                      Colors.transparent,
                      borderColor,
                      labelColor,
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
                      Colors.transparent,
                      borderColor,
                      labelColor,
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
                      borderColor,
                      theme.colorScheme.onPrimary,
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
                      borderColor,
                      Colors.black,
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

  // Theme을 사용하는 버튼
  Widget _snsLoginButton(
    String assetPath,
    String label,
    VoidCallback onTap,
    Color backgroundColor,
    Color borderColor,
    Color labelColor,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(
          color: borderColor,
          width: 2.0,
          style: BorderStyle.solid,
        ),
        color: backgroundColor,
      ),
      child: GestureDetector(
        onTap: onTap,
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
            Text(
              '$label로 시작하기',
              style: TextStyle(
                fontSize: 16,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
