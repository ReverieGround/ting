import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'login/LoginPage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  Offset _shakeOffset = Offset.zero;
  Timer? _shakeTimer;
  bool _isShaking = true;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();

    // 진동 타이머 시작
    _startShaking();

    // 1.5초 후 진동 멈추고
    Future.delayed(const Duration(milliseconds: 1000), () {
      _stopShaking();

      // 2.5초까지 정적 상태 유지 후
      Future.delayed(const Duration(milliseconds: 500), () {
        // 페이드 아웃 시작
        setState(() {
          _opacity = 0.0;
        });

        // 페이드 아웃 끝나면 페이지 전환
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      });
    });
  }

  void _startShaking() {
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _shakeOffset = Offset(
          (_random.nextDouble() - 0.5) * 4,
          (_random.nextDouble() - 0.5) * 4,
        );
      });
    });
  }

  void _stopShaking() {
    _shakeTimer?.cancel();
    _shakeTimer = null;
    setState(() {
      _isShaking = false;
      _shakeOffset = Offset.zero;
    });
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _opacity,
          child: Transform.translate(
            offset: _isShaking ? _shakeOffset : Offset.zero,
            child:  Container(
                padding: EdgeInsets.symmetric(horizontal: 80),
                child: Image.asset(
                  'assets/logo.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),            
          ),
        ),
      ),
    );
  }
}
