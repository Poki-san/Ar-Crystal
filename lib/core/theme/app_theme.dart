import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF080A0B);
  static const Color surface = Color(0xFF111416);
  static const Color surfaceSoft = Color(0xFF171B1E);
  static const Color line = Color(0xFF292E31);
  static const Color text = Color(0xFFF4F5F2);
  static const Color muted = Color(0xFF8C9493);
  static const Color acid = Color(0xFFD8FF63);
  static const Color orange = Color(0xFFFF6B3D);
  static const Color cyan = Color(0xFF5BE7E2);
  static const Color violet = Color(0xFF8E6CFF);
}

abstract final class AppTheme {
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme.dark(
      primary: AppColors.acid,
      secondary: AppColors.orange,
      surface: AppColors.surface,
      onPrimary: AppColors.background,
      onSurface: AppColors.text,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'sans-serif',
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 46,
          height: .94,
          fontWeight: FontWeight.w800,
          letterSpacing: -2.4,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.05,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.text),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xF20C0E0F),
        indicatorColor: Colors.transparent,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
