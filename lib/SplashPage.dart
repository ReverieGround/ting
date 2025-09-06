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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 80),
          child: Image.asset(
            'assets/logo_white.png',
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),            
      ),
    );
  }
}
