import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF021C4B);
  static const Color primaryContainer = Color(0xFF1D3261); // Oxford Blue
  static const Color secondary = Color(0xFF5C5F60);
  static const Color secondaryContainer = Color(0xFFDFE0E1);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color background = Color(0xFFF9F9F9);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onBackground = Color(0xFF1A1C1C);
  static const Color onError = Colors.white;

  // Accents
  static const Color signalRed = Color(0xFFD0021B);
  static const Color performanceGreen = Color(0xFF27AE60);
  static const Color silverMist = Color(0xFFD9DADB);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        error: error,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: onSurface,
        onError: onError,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 48,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01 * 32,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05 * 14,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // 0.25rem = 4px
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: silverMist, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryContainer, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: silverMist, width: 1),
          borderRadius: BorderRadius.circular(8), // 0.5rem = 8px
        ),
      ),
    );
  }
}
