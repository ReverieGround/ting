import 'package:flutter/material.dart';

// 🎨 테마에 사용할 기본 색상 정의
const kBgLight = Color(0xFF0F1115);
// const kPrimary = Color(0xFFF39C12);
const kPrimary = Color(0xFFEAECEF);
const kFontLight = Color(0xFFEAECEF);
// kPrimary = Color(0xFFE74C3C)
// kPrimary = Color(0xFFF39C12)
// kPrimary = Color(0xFF27AE60)
// kPrimary = Color(0xFF2ECC71)

const kBgDark = Color(0xFF0B0D10);
const kFontDark = Color(0xFFEAECEF);

// 💧 투명도 값도 변수로 관리하면 편리합니다
const kHintOpacity = 0.6;
const kBorderOpacity = 0.15;
const kDividerOpacity = 0.12;

class AppTheme {
  // 💡 라이트 테마
  static ThemeData get lightTheme {
    return _buildTheme(
      primaryColor: kPrimary,
      backgroundColor: kBgLight,
      fontColor: kFontLight,
      brightness: Brightness.light,
    );
  }

  // 🌙 다크 테마
  static ThemeData get darkTheme {
    return _buildTheme(
      primaryColor: kPrimary,
      backgroundColor: kBgDark,
      fontColor: kFontDark,
      brightness: Brightness.dark,
    );
  }

  // ✨ 중복 코드를 줄이기 위해 테마 생성 로직을 별도의 함수로 분리
  static ThemeData _buildTheme({
    required Color primaryColor,
    required Color backgroundColor,
    required Color fontColor,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(
      background: backgroundColor,
      surface: backgroundColor,
      onBackground: fontColor,
      onSurface: fontColor,
      primary: primaryColor,
      onPrimary: Colors.black,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: fontColor,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: fontColor),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: fontColor),
        bodyMedium: TextStyle(color: fontColor),
        // 필요한 다른 텍스트 스타일을 여기에 추가
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor.withOpacity(kHintOpacity),
        hintStyle: TextStyle(color: fontColor.withOpacity(kHintOpacity)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fontColor.withOpacity(kBorderOpacity)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fontColor.withOpacity(kBorderOpacity)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      cardColor: backgroundColor,
      dividerColor: fontColor.withOpacity(kDividerOpacity),
    );
  }
}