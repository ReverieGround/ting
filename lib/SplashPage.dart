import 'dart:async';
import 'package:flutter/material.dart';
import 'login/LoginPage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashPage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // 테마 배경색
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Image.asset(
            'assets/logo_white.png',
            width: double.infinity,
            fit: BoxFit.contain,
            // 만약 컬러 로고라면 ColorFilter로 theme.primaryColor 입힐 수도 있음
            // color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
