import 'package:flutter/material.dart';
import 'theme/AppTheme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart'; // required
import 'firebase_options.dart';
import 'SplashPage.dart';
import 'login/LoginPage.dart';
import 'home/HomePage.dart';
import 'onboarding/OnboardingPage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/AuthService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:go_router/go_router.dart';

/// ====== 앱 상태 머신 ======
enum AppStatus { initializing, unauthenticated, needsOnboarding, authenticated }

const bool kForceOnboarding =
    bool.fromEnvironment('FORCE_ONBOARDING', defaultValue: false);

class AppState extends ChangeNotifier {
  AppState({AuthService? auth, this.forceOnboarding = false})
      : auth = auth ?? AuthService();

  final AuthService auth;
  final bool forceOnboarding;

  AppStatus status = AppStatus.initializing;
  String? userId;
  
  Future<void> bootstrap() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        status = AppStatus.unauthenticated;
        notifyListeners();
        return;
      }
      await auth.saveIdToken();
      userId = user.uid;

      // 원래 온보딩 판단
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final needs = !doc.exists ||
          ((doc.data()?['user_name'] as String?)?.isEmpty ?? true) ||
          ((doc.data()?['country_code'] as String?)?.isEmpty ?? true);

      // 디버그용 강제 온보딩
      if (forceOnboarding) {
        status = AppStatus.needsOnboarding;
      } else {
        status = needs ? AppStatus.needsOnboarding : AppStatus.authenticated;
      }
    } catch (_) {
      status = AppStatus.unauthenticated;
    }
    notifyListeners();
  }
}

/// ====== 라우터 ======
GoRouter buildRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appState,
    redirect: (context, state) {
      final here = state.matchedLocation;
      switch (appState.status) {
        case AppStatus.initializing:
          return (here == '/splash') ? null : '/splash';
        case AppStatus.unauthenticated:
          return (here == '/login' || here == '/splash') ? null : '/login';
        case AppStatus.needsOnboarding:
          return (here == '/onboarding') ? null : '/onboarding';
        case AppStatus.authenticated:
          if (here == '/splash' || here == '/login' || here == '/onboarding') {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      // 👇 appState를 직접 주입
      GoRoute(path: '/login', builder: (_, __) => LoginPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => OnboardingPage(appState: appState)),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      // GoRoute(path: '/home', builder: (_, __) => OnboardingPage(appState: appState)),
      
    ],
  );
}
/// ====== main() ======
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final appState = AppState(
    forceOnboarding: kForceOnboarding
  );
  appState.bootstrap();

  runApp(VibeYumApp(appState: appState));
}

class VibeYumApp extends StatelessWidget {
  const VibeYumApp({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(appState);
    return MaterialApp.router(
      title: 'T!ng',
      themeMode: ThemeMode.light, // Force light mode
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
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
