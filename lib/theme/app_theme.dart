import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Made by Anxiety — Design System (Enhanced)
class AppColors {
  AppColors._();

  // --- Background (Eclipse) ---
  static const Color backgroundAnxious = Color(0xFF000000); // True OLED Black
  static const Color backgroundCalm = Color(0xFF040404);
  static const Color background = backgroundAnxious; // Default

  // --- Eclipse Ring (Dynamic) ---
  static const Color fluidAnxious = Color(0xFF7A7A7A); // Visible dim ring
  static const Color fluidCalm = Color(0xFFFFFFFF);    // Pure white ring

  // --- Text ---
  static const Color textPrimary = Color(0xB3FFFFFF);    // 70% white
  static const Color textBrand = Color(0x40FFFFFF);      // 25% white (branding)
  static const Color textHint = Color(0x4DFFFFFF);       // 30% white

  // --- Icons ---
  static const Color iconActive = Color(0xFFE8B4B8);       // Soft Pink/Lavender active tint
  static const Color iconInactive = Color(0x4DFFFFFF);   // 30% white

  // --- Legacy aliases (used by old screens, kept for safety) ---
  static const Color sos = Color(0xFFE8534A);
  static const Color panicBg = Color(0xFF000000);
  static const Color mainBg = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xB3FFFFFF);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle sosLabel = GoogleFonts.lora(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static TextStyle breathInstruction = GoogleFonts.raleway(
    fontSize: 26, // Increased size for better visibility and impact
    fontWeight: FontWeight.w400, // Slightly bolder for emphasis
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    height: 1.6,
  );

  static TextStyle groundingText = GoogleFonts.raleway(
    fontSize: 22,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
    height: 1.6,
    letterSpacing: 0.3,
  );

  static TextStyle groundingHint = GoogleFonts.raleway(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: AppColors.textHint,
    letterSpacing: 0.3,
  );

  static TextStyle controlLabel = GoogleFonts.raleway( // New style for control labels
    fontSize: 10,
    fontWeight: FontWeight.w300,
    color: AppColors.textHint, // Use textHint for consistency
    letterSpacing: 0.5,
  );

  static TextStyle trustCardQuote = GoogleFonts.raleway( // New style for trust card quote
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
    height: 1.7,
  );

  static TextStyle trustCardSource = GoogleFonts.raleway( // New style for trust card source
    fontSize: 11,
    fontWeight: FontWeight.w300,
    color: AppColors.textHint,
    letterSpacing: 0.3,
  );
}

class AppDurations {
  AppDurations._();

  static const Duration tapResponse = Duration(milliseconds: 150);
  static const Duration screenTransition = Duration(milliseconds: 300);
  static const Duration breatheIn = Duration(seconds: 4);
  static const Duration breatheHold = Duration(milliseconds: 1500);
  static const Duration breatheOut = Duration(seconds: 6);
  static const Duration groundingFade = Duration(milliseconds: 400);
  static const Duration controlTapAnimation = Duration(milliseconds: 100); // For subtle tap feedback
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.ralewayTextTheme(ThemeData.dark().textTheme),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.fluidAnxious,
      surface: AppColors.background,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
