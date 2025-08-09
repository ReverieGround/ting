import 'package:flutter/material.dart';
import 'theme/AppTheme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart'; // required
import 'firebase_options.dart'; 
import 'SplashPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: SplashPage(),
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