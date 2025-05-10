import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() {
  runApp(VibeYumApp());
}

class VibeYumApp extends StatelessWidget {
  const VibeYumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeYum',
      themeMode: ThemeMode.light, // Force light mode
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'), // 한국어
        Locale('en'), // 영어 (fallback)
      ],
    );
  }
}