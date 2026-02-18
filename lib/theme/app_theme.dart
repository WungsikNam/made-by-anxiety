import 'package:flutter/material.dart';

/// Made by Anxiety — Design System
class AppColors {
  AppColors._();

  // --- Background ---
  static const Color background = Color(0xFF111111);    // near-black charcoal

  // --- Breathing circle ---
  static const Color breathCircle = Color(0xFF787878);      // warm gray
  static const Color breathCircleGlow = Color(0x18AAAAAA);  // very subtle glow

  // --- Text ---
  static const Color textPrimary = Color(0xB3FFFFFF);    // 70% white
  static const Color textBrand = Color(0x40FFFFFF);      // 25% white (branding)
  static const Color textHint = Color(0x66FFFFFF);       // 40% white

  // --- Icons ---
  static const Color iconActive = Color(0xE6FFFFFF);     // 90% white
  static const Color iconInactive = Color(0x4DFFFFFF);   // 30% white

  // --- Legacy aliases (used by old screens, kept for safety) ---
  static const Color sos = Color(0xFFE8534A);
  static const Color panicBg = Color(0xFF000000);
  static const Color mainBg = Color(0xFF111111);
  static const Color textSecondary = Color(0xB3FFFFFF);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle sosLabel = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static const TextStyle breathInstruction = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
    height: 1.5,
  );

  static const TextStyle groundingText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
    letterSpacing: 0.2,
  );

  static const TextStyle groundingHint = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: AppColors.textHint,
    letterSpacing: 0.3,
  );
}

class AppDurations {
  AppDurations._();

  // Calm: 600~800ms (여유) → Panic Zero: 즉각 반응 우선
  static const Duration tapResponse = Duration(milliseconds: 150);
  static const Duration screenTransition = Duration(milliseconds: 250);
  static const Duration breatheIn = Duration(seconds: 4);   // 생리적 한숨: 코 흡기
  static const Duration breatheHold = Duration(milliseconds: 1500);
  static const Duration breatheOut = Duration(seconds: 6);  // 긴 날숨
  static const Duration groundingFade = Duration(milliseconds: 300);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.breathCircle,
      surface: AppColors.background,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
